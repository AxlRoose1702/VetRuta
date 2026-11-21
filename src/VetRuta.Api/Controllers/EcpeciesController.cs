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
public class EspeciesController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<EspecieResponse>>> Listar() =>
        Ok(await db.Especies
            .OrderBy(e => e.Nombre)
            .Select(e => new EspecieResponse(e.Id, e.Nombre, e.Razas.Count))
            .ToListAsync());

    [HttpGet("{id:int}")]
    public async Task<ActionResult<EspecieResponse>> Obtener(int id)
    {
        var e = await db.Especies.Where(x => x.Id == id)
            .Select(x => new EspecieResponse(x.Id, x.Nombre, x.Razas.Count))
            .FirstOrDefaultAsync();
        return e == null ? NotFound(new { mensaje = "Especie no encontrada" }) : Ok(e);
    }

    // GET api/especies/5/razas  -> para el combo de razas al elegir especie
    [HttpGet("{id:int}/razas")]
    public async Task<ActionResult<IEnumerable<RazaResponse>>> Razas(int id)
    {
        if (!await db.Especies.AnyAsync(e => e.Id == id)) return NotFound(new { mensaje = "Especie no encontrada" });
        return Ok(await db.Razas
            .Where(r => r.EspecieId == id)
            .OrderBy(r => r.Nombre)
            .Select(r => new RazaResponse(r.Id, r.Nombre, r.EspecieId, r.Especie!.Nombre))
            .ToListAsync());
    }

    [HttpPost]
    [Authorize(Roles = $"{Roles.Root},{Roles.Director}")]
    public async Task<ActionResult<EspecieResponse>> Crear(EspecieRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Nombre)) return BadRequest(new { mensaje = "El nombre es obligatorio" });
        if (await db.Especies.AnyAsync(e => e.Nombre == req.Nombre))
            return Conflict(new { mensaje = "Ya existe esa especie" });

        var especie = new Especie { Nombre = req.Nombre.Trim() };
        db.Especies.Add(especie);
        await db.SaveChangesAsync();
        return CreatedAtAction(nameof(Obtener), new { id = especie.Id }, new EspecieResponse(especie.Id, especie.Nombre, 0));
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = $"{Roles.Root},{Roles.Director}")]
    public async Task<IActionResult> Editar(int id, EspecieRequest req)
    {
        var especie = await db.Especies.FindAsync(id);
        if (especie == null) return NotFound(new { mensaje = "Especie no encontrada" });
        if (string.IsNullOrWhiteSpace(req.Nombre)) return BadRequest(new { mensaje = "El nombre es obligatorio" });
        if (await db.Especies.AnyAsync(e => e.Nombre == req.Nombre && e.Id != id))
            return Conflict(new { mensaje = "Ya existe esa especie" });

        especie.Nombre = req.Nombre.Trim();
        await db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = $"{Roles.Root},{Roles.Director}")]
    public async Task<IActionResult> Eliminar(int id)
    {
        var especie = await db.Especies.FindAsync(id);
        if (especie == null) return NotFound(new { mensaje = "Especie no encontrada" });
        if (await db.Razas.AnyAsync(r => r.EspecieId == id))
            return Conflict(new { mensaje = "No se puede eliminar: la especie tiene razas" });

        db.Especies.Remove(especie);
        await db.SaveChangesAsync();
        return NoContent();
    }
}