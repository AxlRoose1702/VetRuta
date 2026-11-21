using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using VetRuta.Api.Dtos;
using VetRuta.Domain.Entities;
using VetRuta.Infrastructure.Data;

namespace VetRuta.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class VisitasController(AppDbContext db, IWebHostEnvironment env) : ControllerBase
{
    private const string Programadores = $"{Roles.Root},{Roles.Director},{Roles.Medico}";
    private static readonly string[] ExtensionesFoto = { ".jpg", ".jpeg", ".png" };
    private const long MaxFotoBytes = 5 * 1024 * 1024; // 5 MB

    private string UsuarioActualId => User.FindFirstValue(ClaimTypes.NameIdentifier)!;

    // GET api/visitas?desde=2026-11-01&hasta=2026-11-30&estado=Programada&atrasadas=true&tecnicoId=abc&pacienteId=1
    [HttpGet]
    public async Task<ActionResult<IEnumerable<VisitaResponse>>> Listar(
        [FromQuery] DateTime? desde, [FromQuery] DateTime? hasta,
        [FromQuery] EstadoVisita? estado, [FromQuery] bool? atrasadas,
        [FromQuery] string? tecnicoId, [FromQuery] int? pacienteId)
    {
        var ahora = DateTime.UtcNow;
        var query = VisitasVisibles();

        if (desde.HasValue) query = query.Where(v => v.FechaProgramada >= desde.Value);
        if (hasta.HasValue) query = query.Where(v => v.FechaProgramada < hasta.Value.Date.AddDays(1));
        if (estado.HasValue) query = query.Where(v => v.Estado == estado.Value);
        if (atrasadas == true) query = query.Where(v => v.Estado == EstadoVisita.Programada && v.FechaProgramada < ahora);
        if (!string.IsNullOrWhiteSpace(tecnicoId)) query = query.Where(v => v.TecnicoId == tecnicoId);
        if (pacienteId.HasValue) query = query.Where(v => v.PacienteId == pacienteId.Value);

        return Ok(await Proyectar(query.OrderBy(v => v.FechaProgramada), ahora).ToListAsync());
    }

    // GET api/visitas/5
    [HttpGet("{id:int}")]
    public async Task<ActionResult<VisitaResponse>> Obtener(int id)
    {
        var v = await Proyectar(VisitasVisibles().Where(x => x.Id == id), DateTime.UtcNow).FirstOrDefaultAsync();
        return v == null ? NotFound(new { mensaje = "Visita no encontrada" }) : Ok(v);
    }

    // POST api/visitas  (programar)
    [HttpPost]
    [Authorize(Roles = Programadores)]
    public async Task<ActionResult<VisitaResponse>> Programar(ProgramarVisitaRequest req)
    {
        var paciente = await PacientesVisibles().FirstOrDefaultAsync(p => p.Id == req.PacienteId);
        if (paciente == null) return BadRequest(new { mensaje = "El paciente no existe o no te corresponde" });
        if (string.IsNullOrEmpty(paciente.TecnicoId))
            return BadRequest(new { mensaje = "El paciente no tiene técnico asignado" });
        if (!await db.Servicios.AnyAsync(s => s.Id == req.ServicioId))
            return BadRequest(new { mensaje = "El servicio no existe" });
        if (req.FechaProgramada < DateTime.UtcNow)
            return BadRequest(new { mensaje = "No se puede programar en una fecha pasada" });

        var visita = new Visita
        {
            PacienteId = paciente.Id,
            ServicioId = req.ServicioId,
            TecnicoId = paciente.TecnicoId,
            FechaProgramada = req.FechaProgramada,
            Estado = EstadoVisita.Programada
        };
        db.Visitas.Add(visita);
        await db.SaveChangesAsync();

        var resp = await Proyectar(db.Visitas.Where(v => v.Id == visita.Id), DateTime.UtcNow).FirstAsync();
        return CreatedAtAction(nameof(Obtener), new { id = visita.Id }, resp);
    }

    // PUT api/visitas/5/fecha  (reprogramar)
    [HttpPut("{id:int}/fecha")]
    [Authorize(Roles = Programadores)]
    public async Task<IActionResult> Reprogramar(int id, ReprogramarVisitaRequest req)
    {
        var visita = await VisitasVisibles().FirstOrDefaultAsync(v => v.Id == id);
        if (visita == null) return NotFound(new { mensaje = "Visita no encontrada" });
        if (visita.Estado != EstadoVisita.Programada)
            return Conflict(new { mensaje = "Solo se pueden reprogramar visitas programadas" });
        if (req.FechaProgramada < DateTime.UtcNow)
            return BadRequest(new { mensaje = "No se puede programar en una fecha pasada" });

        visita.FechaProgramada = req.FechaProgramada;
        await db.SaveChangesAsync();
        return NoContent();
    }

    // PUT api/visitas/5/cancelar
    [HttpPut("{id:int}/cancelar")]
    [Authorize(Roles = Programadores)]
    public async Task<IActionResult> Cancelar(int id)
    {
        var visita = await VisitasVisibles().FirstOrDefaultAsync(v => v.Id == id);
        if (visita == null) return NotFound(new { mensaje = "Visita no encontrada" });
        if (visita.Estado != EstadoVisita.Programada)
            return Conflict(new { mensaje = "Solo se pueden cancelar visitas programadas" });

        visita.Estado = EstadoVisita.Cancelada;
        await db.SaveChangesAsync();
        return NoContent();
    }

    // POST api/visitas/5/registro  (multipart/form-data)
    [HttpPost("{id:int}/registro")]
    [Authorize(Roles = Roles.Tecnico)]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(MaxFotoBytes + 1024 * 1024)]
    public async Task<ActionResult<VisitaResponse>> Registrar(int id, [FromForm] RegistrarVisitaRequest req)
    {
        var visita = await db.Visitas.FirstOrDefaultAsync(v => v.Id == id && v.TecnicoId == UsuarioActualId);
        if (visita == null) return NotFound(new { mensaje = "Visita no encontrada" });

        // Solo lectura una vez registrada
        if (visita.Estado == EstadoVisita.Realizada)
            return Conflict(new { mensaje = "La visita ya fue registrada y es de solo lectura" });
        if (visita.Estado == EstadoVisita.Cancelada)
            return Conflict(new { mensaje = "La visita está cancelada" });

        var error = ValidarRegistro(req);
        if (error != null) return BadRequest(new { mensaje = error });

        visita.FotoUrl = await GuardarFotoAsync(req.Foto!, visita.Id);
        visita.PesoKg = req.PesoKg;
        visita.AlturaCm = req.AlturaCm;
        visita.Temperatura = req.Temperatura;
        visita.Condicion = req.Condicion.Trim();
        visita.Latitud = req.Latitud;
        visita.Longitud = req.Longitud;
        visita.FechaRegistro = DateTime.UtcNow;
        visita.Estado = EstadoVisita.Realizada;
        await db.SaveChangesAsync();

        return Ok(await Proyectar(db.Visitas.Where(v => v.Id == id), DateTime.UtcNow).FirstAsync());
    }

    // ---------- privados ----------

    private IQueryable<Paciente> PacientesVisibles()
    {
        var yo = UsuarioActualId;
        if (User.IsInRole(Roles.Tecnico)) return db.Pacientes.Where(p => p.TecnicoId == yo);
        if (User.IsInRole(Roles.Medico))
            return db.Pacientes.Where(p => db.Users.Any(u => u.Id == p.TecnicoId && u.MedicoId == yo));
        return db.Pacientes;
    }

    private IQueryable<Visita> VisitasVisibles()
    {
        var yo = UsuarioActualId;
        if (User.IsInRole(Roles.Tecnico)) return db.Visitas.Where(v => v.TecnicoId == yo);
        if (User.IsInRole(Roles.Medico))
            return db.Visitas.Where(v => db.Users.Any(u => u.Id == v.TecnicoId && u.MedicoId == yo));
        return db.Visitas;
    }

    private static string? ValidarRegistro(RegistrarVisitaRequest r)
    {
        if (r.PesoKg <= 0 || r.PesoKg > 1000) return "El peso debe estar entre 0 y 1000 kg";
        if (r.AlturaCm <= 0 || r.AlturaCm > 300) return "La altura debe estar entre 0 y 300 cm";
        if (r.Temperatura < 30 || r.Temperatura > 45) return "La temperatura debe estar entre 30 y 45 °C";
        if (string.IsNullOrWhiteSpace(r.Condicion)) return "La condición es obligatoria";
        if (r.Latitud is < -90 or > 90 || r.Longitud is < -180 or > 180) return "Ubicación inválida";
        if (r.Foto == null || r.Foto.Length == 0) return "La foto es obligatoria";
        if (r.Foto.Length > MaxFotoBytes) return "La foto no puede pesar más de 5 MB";
        if (!ExtensionesFoto.Contains(Path.GetExtension(r.Foto.FileName).ToLowerInvariant()))
            return "La foto debe ser JPG o PNG";
        return null;
    }

    private async Task<string> GuardarFotoAsync(IFormFile foto, int visitaId)
    {
        var raiz = env.WebRootPath ?? Path.Combine(env.ContentRootPath, "wwwroot");
        var carpeta = Path.Combine(raiz, "fotos");
        Directory.CreateDirectory(carpeta);

        var nombre = $"visita-{visitaId}-{Guid.NewGuid():N}{Path.GetExtension(foto.FileName).ToLowerInvariant()}";
        await using var stream = System.IO.File.Create(Path.Combine(carpeta, nombre));
        await foto.CopyToAsync(stream);
        return $"/fotos/{nombre}";
    }

    private IQueryable<VisitaResponse> Proyectar(IQueryable<Visita> query, DateTime ahora) =>
        query.Select(v => new VisitaResponse(
            v.Id,
            v.PacienteId, v.Paciente!.Nombre,
            v.Paciente.Raza!.Especie!.Nombre, v.Paciente.Duenio!.Nombre,
            v.ServicioId, v.Servicio!.Nombre,
            v.TecnicoId,
            db.Users.Where(u => u.Id == v.TecnicoId).Select(u => u.NombreCompleto).FirstOrDefault(),
            v.FechaProgramada,
            v.Estado.ToString(),
            v.Estado == EstadoVisita.Programada && v.FechaProgramada < ahora,
            v.FechaRegistro,
            v.PesoKg, v.AlturaCm, v.Temperatura,
            v.Condicion,
            v.Latitud, v.Longitud,
            v.FotoUrl));
}