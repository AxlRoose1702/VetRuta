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
public class PacientesController(AppDbContext db) : ControllerBase
{
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

    // POST api/pacientes
    [HttpPost]
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
            TecnicoId = tecnicoId
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
        await db.SaveChangesAsync();
        return NoContent();
    }

    // PUT api/pacientes/5/tecnico
    [HttpPut("{id:int}/tecnico")]
    [Authorize(Roles = $"{Roles.Root},{Roles.Director},{Roles.Medico}")]
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

    // Decide qué técnico queda asignado según quién hace la petición
    private async Task<(string? tecnicoId, ActionResult? error)> ResolverTecnicoAsync(string? tecnicoPedido)
    {
        if (User.IsInRole(Roles.Tecnico))
            return (UsuarioActualId, null); // el técnico siempre se asigna a sí mismo

        if (string.IsNullOrWhiteSpace(tecnicoPedido))
            return (null, BadRequest(new { mensaje = "Debes indicar el técnico" }));

        var tecnicoRolId = await db.Roles.Where(r => r.Name == Roles.Tecnico).Select(r => r.Id).FirstAsync();
        var tecnico = await db.Users.FirstOrDefaultAsync(u =>
            u.Id == tecnicoPedido && db.UserRoles.Any(ur => ur.UserId == u.Id && ur.RoleId == tecnicoRolId));

        if (tecnico == null) return (null, BadRequest(new { mensaje = "El técnico no existe" }));
        if (!tecnico.Activo) return (null, BadRequest(new { mensaje = "El técnico está desactivado" }));

        if (User.IsInRole(Roles.Medico) && tecnico.MedicoId != UsuarioActualId)
            return (null, BadRequest(new { mensaje = "Ese técnico no está asignado a ti" }));

        return (tecnico.Id, null);
    }

    private async Task<ActionResult?> ValidarDatosAsync(PacienteRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Nombre)) return BadRequest(new { mensaje = "El nombre es obligatorio" });
        if (req.FechaNacimiento > DateTime.Today) return BadRequest(new { mensaje = "La fecha de nacimiento no puede ser futura" });
        if (!await db.Razas.AnyAsync(r => r.Id == req.RazaId)) return BadRequest(new { mensaje = "La raza no existe" });
        if (!await db.Dueños.AnyAsync(d => d.Id == req.DuenoId)) return BadRequest(new { mensaje = "El dueño no existe" });
        return null;
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
            p.Duenio!.Nombre,
            p.Duenio.Telefono,
            p.TecnicoId,
            db.Users.Where(u => u.Id == p.TecnicoId).Select(u => u.NombreCompleto).FirstOrDefault()));
}