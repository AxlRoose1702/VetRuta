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
public class PacientesController(AppDbContext db, IWebHostEnvironment env) : ControllerBase
{
    private static readonly string[] ExtensionesFoto = { ".jpg", ".jpeg", ".png" };
    private const long MaxFotoBytes = 5 * 1024 * 1024; // 5 MB

    private string UsuarioActualId => User.FindFirstValue(ClaimTypes.NameIdentifier)!;

    // GET api/pacientes?buscar=firulais&especieId=1&duenoId=3&tecnicoId=abc
    [HttpGet]
    public async Task<ActionResult<IEnumerable<PacienteResponse>>> Listar(
        [FromQuery] string? buscar, [FromQuery] int? especieId, [FromQuery] int? duenoId, [FromQuery] string? tecnicoId)
    {
        var query = PacientesVisibles();

        if (!string.IsNullOrWhiteSpace(buscar)) query = query.Where(p => p.Nombre.Contains(buscar));
        if (especieId.HasValue) query = query.Where(p => p.Raza!.EspecieId == especieId);
        if (duenoId.HasValue) query = query.Where(p => p.DuenoId == duenoId);
        if (!string.IsNullOrWhiteSpace(tecnicoId)) query = query.Where(p => p.TecnicoId == tecnicoId);

        return Ok(await Proyectar(query.OrderBy(p => p.Nombre)).ToListAsync());
    }

    // GET api/pacientes/5
    [HttpGet("{id:int}")]
    public async Task<ActionResult<PacienteResponse>> Obtener(int id)
    {
        var p = await Proyectar(PacientesVisibles().Where(x => x.Id == id)).FirstOrDefaultAsync();
        return p == null ? NotFound(new { mensaje = "Paciente no encontrado" }) : Ok(p);
    }

    // GET api/pacientes/5/historial
    [HttpGet("{id:int}/historial")]
    public async Task<ActionResult<HistorialPacienteResponse>> Historial(int id)
    {
        var paciente = await Proyectar(PacientesVisibles().Where(p => p.Id == id)).FirstOrDefaultAsync();
        if (paciente == null) return NotFound(new { mensaje = "Paciente no encontrado" });

        var ahora = DateTime.UtcNow;
        var visitas = await db.Visitas
            .Where(v => v.PacienteId == id)
            .OrderByDescending(v => v.FechaRegistro ?? v.FechaProgramada)
            .Select(v => new VisitaResponse(
                v.Id,
                v.PacienteId, v.Paciente!.Nombre,
                v.Paciente.Raza!.Especie!.Nombre, v.Paciente.Dueno!.Nombre,
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
                v.FotoUrl,
                v.Observaciones))
            .ToListAsync();

        var realizadas = visitas.Where(v => v.Estado == nameof(EstadoVisita.Realizada)).ToList();

        return Ok(new HistorialPacienteResponse(
            paciente,
            visitas.Count,
            realizadas.Count,
            realizadas.Max(v => v.FechaRegistro),
            visitas));
    }

    // POST api/pacientes  (solo el Médico crea pacientes y los asigna a uno de sus técnicos)
    [HttpPost]
    [Authorize(Roles = Roles.Medico)]
    public async Task<ActionResult<PacienteResponse>> Crear(PacienteRequest req)
    {
        var (tecnicoId, error) = await ResolverTecnicoAsync(req.TecnicoId);
        if (error != null) return error;

        var errorDatos = await ValidarDatosAsync(req);
        if (errorDatos != null) return errorDatos;

        var paciente = new Paciente
        {
            Nombre = req.Nombre.Trim(),
            FechaNacimiento = req.FechaNacimiento,
            RazaId = req.RazaId,
            DuenoId = req.DuenoId,
            TecnicoId = tecnicoId,
            Latitud = req.Latitud,
            Longitud = req.Longitud
        };
        db.Pacientes.Add(paciente);
        await db.SaveChangesAsync();

        var resp = await Proyectar(db.Pacientes.Where(p => p.Id == paciente.Id)).FirstAsync();
        return CreatedAtAction(nameof(Obtener), new { id = paciente.Id }, resp);
    }

    // PUT api/pacientes/5  (no cambia el técnico, para eso está /tecnico)
    [HttpPut("{id:int}")]
    public async Task<IActionResult> Editar(int id, PacienteRequest req)
    {
        var paciente = await PacientesVisibles().FirstOrDefaultAsync(p => p.Id == id);
        if (paciente == null) return NotFound(new { mensaje = "Paciente no encontrado" });

        var errorDatos = await ValidarDatosAsync(req);
        if (errorDatos != null) return errorDatos;

        paciente.Nombre = req.Nombre.Trim();
        paciente.FechaNacimiento = req.FechaNacimiento;
        paciente.RazaId = req.RazaId;
        paciente.DuenoId = req.DuenoId;
        if (req.Latitud.HasValue && req.Longitud.HasValue) // si no la mandan, se conserva la que tenía
        {
            paciente.Latitud = req.Latitud;
            paciente.Longitud = req.Longitud;
        }
        await db.SaveChangesAsync();
        return NoContent();
    }

    // PUT api/pacientes/5/tecnico  (solo el Médico, entre sus técnicos)
    [HttpPut("{id:int}/tecnico")]
    [Authorize(Roles = Roles.Medico)]
    public async Task<IActionResult> ReasignarTecnico(int id, ReasignarTecnicoRequest req)
    {
        var paciente = await PacientesVisibles().FirstOrDefaultAsync(p => p.Id == id);
        if (paciente == null) return NotFound(new { mensaje = "Paciente no encontrado" });

        var (tecnicoId, error) = await ResolverTecnicoAsync(req.TecnicoId);
        if (error != null) return error;

        paciente.TecnicoId = tecnicoId;
        await db.SaveChangesAsync();
        return NoContent();
    }

    // POST api/pacientes/5/foto  (multipart/form-data)
    [HttpPost("{id:int}/foto")]
    [Authorize(Roles = $"{Roles.Medico},{Roles.Tecnico}")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(MaxFotoBytes + 1024 * 1024)]
    public async Task<ActionResult<PacienteResponse>> SubirFoto(int id, [FromForm] FotoPacienteRequest req)
    {
        var paciente = await PacientesVisibles().FirstOrDefaultAsync(p => p.Id == id);
        if (paciente == null) return NotFound(new { mensaje = "Paciente no encontrado" });

        if (req.Foto == null || req.Foto.Length == 0) return BadRequest(new { mensaje = "La foto es obligatoria" });
        if (req.Foto.Length > MaxFotoBytes) return BadRequest(new { mensaje = "La foto no puede pesar más de 5 MB" });
        if (!ExtensionesFoto.Contains(Path.GetExtension(req.Foto.FileName).ToLowerInvariant()))
            return BadRequest(new { mensaje = "La foto debe ser JPG o PNG" });

        paciente.FotoUrl = await GuardarFotoAsync(req.Foto, $"paciente-{paciente.Id}");
        await db.SaveChangesAsync();

        return Ok(await Proyectar(db.Pacientes.Where(p => p.Id == id)).FirstAsync());
    }

    // DELETE api/pacientes/5
    [HttpDelete("{id:int}")]
    [Authorize(Roles = $"{Roles.Root},{Roles.Director}")]
    public async Task<IActionResult> Eliminar(int id)
    {
        var paciente = await db.Pacientes.FindAsync(id);
        if (paciente == null) return NotFound(new { mensaje = "Paciente no encontrado" });
        if (await db.Visitas.AnyAsync(v => v.PacienteId == id))
            return Conflict(new { mensaje = "No se puede eliminar: el paciente tiene visitas" });

        db.Pacientes.Remove(paciente);
        await db.SaveChangesAsync();
        return NoContent();
    }

    // ---------- privados ----------

    // La jerarquía: cada rol solo ve los pacientes que le tocan
    private IQueryable<Paciente> PacientesVisibles()
    {
        var query = db.Pacientes.AsQueryable();

        if (User.IsInRole(Roles.Tecnico))
            return query.Where(p => p.TecnicoId == UsuarioActualId);

        if (User.IsInRole(Roles.Medico))
        {
            var yo = UsuarioActualId;
            return query.Where(p => db.Users.Any(u => u.Id == p.TecnicoId && u.MedicoId == yo));
        }

        return query; // Root y Director ven todo
    }

    // Solo la usa el Médico: el técnico debe existir, estar activo y ser suyo
    private async Task<(string? tecnicoId, ActionResult? error)> ResolverTecnicoAsync(string? tecnicoPedido)
    {
        if (string.IsNullOrWhiteSpace(tecnicoPedido))
            return (null, BadRequest(new { mensaje = "Debes indicar el técnico" }));

        var tecnicoRolId = await db.Roles.Where(r => r.Name == Roles.Tecnico).Select(r => r.Id).FirstAsync();
        var tecnico = await db.Users.FirstOrDefaultAsync(u =>
            u.Id == tecnicoPedido && db.UserRoles.Any(ur => ur.UserId == u.Id && ur.RoleId == tecnicoRolId));

        if (tecnico == null) return (null, BadRequest(new { mensaje = "El técnico no existe" }));
        if (!tecnico.Activo) return (null, BadRequest(new { mensaje = "El técnico está desactivado" }));
        if (tecnico.MedicoId != UsuarioActualId)
            return (null, BadRequest(new { mensaje = "Ese técnico no está asignado a ti" }));

        return (tecnico.Id, null);
    }

    private async Task<ActionResult?> ValidarDatosAsync(PacienteRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Nombre)) return BadRequest(new { mensaje = "El nombre es obligatorio" });
        if (req.FechaNacimiento > DateTime.Today) return BadRequest(new { mensaje = "La fecha de nacimiento no puede ser futura" });
        if (req.Latitud.HasValue != req.Longitud.HasValue)
            return BadRequest(new { mensaje = "Manda la latitud y la longitud juntas" });
        if (req.Latitud is < -90 or > 90 || req.Longitud is < -180 or > 180)
            return BadRequest(new { mensaje = "Ubicación inválida" });
        if (!await db.Razas.AnyAsync(r => r.Id == req.RazaId)) return BadRequest(new { mensaje = "La raza no existe" });
        if (!await db.Dueños.AnyAsync(d => d.Id == req.DuenoId)) return BadRequest(new { mensaje = "El dueño no existe" });
        return null;
    }

    private async Task<string> GuardarFotoAsync(IFormFile foto, string prefijo)
    {
        var raiz = env.WebRootPath ?? Path.Combine(env.ContentRootPath, "wwwroot");
        var carpeta = Path.Combine(raiz, "fotos");
        Directory.CreateDirectory(carpeta);

        var nombre = $"{prefijo}-{Guid.NewGuid():N}{Path.GetExtension(foto.FileName).ToLowerInvariant()}";
        await using var stream = System.IO.File.Create(Path.Combine(carpeta, nombre));
        await foto.CopyToAsync(stream);
        return $"/fotos/{nombre}";
    }

    // Convierte a DTO dentro de la consulta SQL
    private IQueryable<PacienteResponse> Proyectar(IQueryable<Paciente> query) =>
        query.Select(p => new PacienteResponse(
            p.Id,
            p.Nombre,
            p.FechaNacimiento,
            p.RazaId,
            p.Raza!.Nombre,
            p.Raza.EspecieId,
            p.Raza.Especie!.Nombre,
            p.DuenoId,
            p.Dueno!.Nombre,
            p.Dueno.Telefono,
            p.TecnicoId,
            db.Users.Where(u => u.Id == p.TecnicoId).Select(u => u.NombreCompleto).FirstOrDefault(),
            p.FotoUrl,
            p.Latitud,
            p.Longitud));
}