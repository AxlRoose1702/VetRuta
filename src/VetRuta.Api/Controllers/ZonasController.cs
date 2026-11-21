using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetRuta.Domain.Entities;
using VetRuta.Infrastructure.Data;
using static VetRuta.Api.Dtos.CatalogoDtos;

namespace VetRuta.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ZonasController(AppDbContext db) : ControllerBase
{
    // GET api/zonas?activo=true
    [HttpGet]
    public async Task<ActionResult<IEnumerable<ZonaResponse>>> Listar([FromQuery] bool? activo)
    {
        var query = db.Zonas.AsQueryable();
        if (activo.HasValue) query = query.Where(z => z.Activo == activo.Value);

        var zonas = await query
            .OrderBy(z => z.Nombre)
            .Select(z => new ZonaResponse(z.Id, z.Nombre, z.Descripcion, z.Activo,
                db.Users.Count(u => u.ZonaId == z.Id)))
            .ToListAsync();
        return Ok(zonas);
    }

    // GET api/zonas/5
    [HttpGet("{id:int}")]
    public async Task<ActionResult<ZonaResponse>> Obtener(int id)
    {
        var zona = await db.Zonas
            .Where(z => z.Id == id)
            .Select(z => new ZonaResponse(z.Id, z.Nombre, z.Descripcion, z.Activo,
                db.Users.Count(u => u.ZonaId == z.Id)))
            .FirstOrDefaultAsync();
        return zona == null ? NotFound(new { mensaje = "Zona no encontrada" }) : Ok(zona);
    }

    // POST api/zonas
    [HttpPost]
    [Authorize(Roles = $"{Roles.Root},{Roles.Director}")]
    public async Task<ActionResult<ZonaResponse>> Crear(ZonaRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Nombre)) return BadRequest(new { mensaje = "El nombre es obligatorio" });
        if (await db.Zonas.AnyAsync(z => z.Nombre == req.Nombre))
            return Conflict(new { mensaje = "Ya existe una zona con ese nombre" });

        var zona = new Zona { Nombre = req.Nombre.Trim(), Descripcion = req.Descripcion, Activo = true };
        db.Zonas.Add(zona);
        await db.SaveChangesAsync();

        return CreatedAtAction(nameof(Obtener), new { id = zona.Id },
            new ZonaResponse(zona.Id, zona.Nombre, zona.Descripcion, zona.Activo, 0));
    }

    // PUT api/zonas/5
    [HttpPut("{id:int}")]
    [Authorize(Roles = $"{Roles.Root},{Roles.Director}")]
    public async Task<IActionResult> Editar(int id, ZonaRequest req)
    {
        var zona = await db.Zonas.FindAsync(id);
        if (zona == null) return NotFound(new { mensaje = "Zona no encontrada" });
        if (string.IsNullOrWhiteSpace(req.Nombre)) return BadRequest(new { mensaje = "El nombre es obligatorio" });
        if (await db.Zonas.AnyAsync(z => z.Nombre == req.Nombre && z.Id != id))
            return Conflict(new { mensaje = "Ya existe una zona con ese nombre" });

        zona.Nombre = req.Nombre.Trim();
        zona.Descripcion = req.Descripcion;
        await db.SaveChangesAsync();
        return NoContent();
    }

    // PATCH api/zonas/5/activar   y   PATCH api/zonas/5/desactivar
    [HttpPatch("{id:int}/activar")]
    [Authorize(Roles = $"{Roles.Root},{Roles.Director}")]
    public Task<IActionResult> Activar(int id) => CambiarEstado(id, true);

    [HttpPatch("{id:int}/desactivar")]
    [Authorize(Roles = $"{Roles.Root},{Roles.Director}")]
    public Task<IActionResult> Desactivar(int id) => CambiarEstado(id, false);

    // GET api/zonas/5/tecnicos
    [HttpGet("{id:int}/tecnicos")]
    [Authorize(Roles = $"{Roles.Root},{Roles.Director},{Roles.Medico}")]
    public async Task<IActionResult> Tecnicos(int id)
    {
        var tecnicoRolId = await db.Roles.Where(r => r.Name == Roles.Tecnico).Select(r => r.Id).FirstAsync();
        var tecnicos = await db.Users
            .Where(u => u.ZonaId == id && db.UserRoles.Any(ur => ur.UserId == u.Id && ur.RoleId == tecnicoRolId))
            .OrderBy(u => u.NombreCompleto)
            .Select(u => new { u.Id, u.NombreCompleto, u.Email, u.Activo, u.MedicoId })
            .ToListAsync();
        return Ok(tecnicos);
    }

    private async Task<IActionResult> CambiarEstado(int id, bool activo)
    {
        var zona = await db.Zonas.FindAsync(id);
        if (zona == null) return NotFound(new { mensaje = "Zona no encontrada" });
        zona.Activo = activo;
        await db.SaveChangesAsync();
        return NoContent();
    }
}