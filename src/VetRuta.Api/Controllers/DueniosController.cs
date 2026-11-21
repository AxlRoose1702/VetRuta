using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetRuta.Api.Dtos;
using VetRuta.Domain.Entities;
using VetRuta.Infrastructure.Data;

namespace VetRuta.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class DuenosController(AppDbContext db) : ControllerBase
{
    // GET api/duenos?buscar=juan
    [HttpGet]
    public async Task<ActionResult<IEnumerable<DuenoResponse>>> Listar([FromQuery] string? buscar)
    {
        var query = db.Dueños.AsQueryable();
        if (!string.IsNullOrWhiteSpace(buscar))
            query = query.Where(d => d.Nombre.Contains(buscar) || (d.Telefono != null && d.Telefono.Contains(buscar)));

        return Ok(await query
            .OrderBy(d => d.Nombre)
            .Select(d => new DuenoResponse(d.Id, d.Nombre, d.Telefono, d.Direccion, d.Pacientes.Count))
            .ToListAsync());
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<DuenoResponse>> Obtener(int id)
    {
        var d = await db.Dueños.Where(x => x.Id == id)
            .Select(x => new DuenoResponse(x.Id, x.Nombre, x.Telefono, x.Direccion, x.Pacientes.Count))
            .FirstOrDefaultAsync();
        return d == null ? NotFound(new { mensaje = "Dueño no encontrado" }) : Ok(d);
    }

    [HttpPost]
    public async Task<ActionResult<DuenoResponse>> Crear(DuenoRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Nombre)) return BadRequest(new { mensaje = "El nombre es obligatorio" });

        var d = new Dueno { Nombre = req.Nombre.Trim(), Telefono = req.Telefono, Direccion = req.Direccion };
        db.Dueños.Add(d);
        await db.SaveChangesAsync();
        return CreatedAtAction(nameof(Obtener), new { id = d.Id },
            new DuenoResponse(d.Id, d.Nombre, d.Telefono, d.Direccion, 0));
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Editar(int id, DuenoRequest req)
    {
        var d = await db.Dueños.FindAsync(id);
        if (d == null) return NotFound(new { mensaje = "Dueño no encontrado" });
        if (string.IsNullOrWhiteSpace(req.Nombre)) return BadRequest(new { mensaje = "El nombre es obligatorio" });

        d.Nombre = req.Nombre.Trim();
        d.Telefono = req.Telefono;
        d.Direccion = req.Direccion;
        await db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = $"{Roles.Root},{Roles.Director}")]
    public async Task<IActionResult> Eliminar(int id)
    {
        var d = await db.Dueños.FindAsync(id);
        if (d == null) return NotFound(new { mensaje = "Dueño no encontrado" });
        if (await db.Pacientes.AnyAsync(p => p.DuenoId == id))
            return Conflict(new { mensaje = "No se puede eliminar: el dueño tiene pacientes" });

        db.Dueños.Remove(d);
        await db.SaveChangesAsync();
        return NoContent();
    }
}