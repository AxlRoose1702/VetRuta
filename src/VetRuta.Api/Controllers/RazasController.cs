using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VetRuta.Api.Dtos;
using VetRuta.Domain;
using VetRuta.Domain.Entities;
using VetRuta.Infrastructure.Data;
using static VetRuta.Api.Dtos.CatalogoDtos;

namespace VetRuta.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class RazasController(AppDbContext db) : ControllerBase
{
    // GET api/razas?especieId=1
    [HttpGet]
    public async Task<ActionResult<IEnumerable<RazaResponse>>> Listar([FromQuery] int? especieId)
    {
        var query = db.Razas.AsQueryable();
        if (especieId.HasValue) query = query.Where(r => r.EspecieId == especieId);

        return Ok(await query
            .OrderBy(r => r.Especie!.Nombre).ThenBy(r => r.Nombre)
            .Select(r => new RazaResponse(r.Id, r.Nombre, r.EspecieId, r.Especie!.Nombre))
            .ToListAsync());
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<RazaResponse>> Obtener(int id)
    {
        var r = await db.Razas.Where(x => x.Id == id)
            .Select(x => new RazaResponse(x.Id, x.Nombre, x.EspecieId, x.Especie!.Nombre))
            .FirstOrDefaultAsync();
        return r == null ? NotFound(new { mensaje = "Raza no encontrada" }) : Ok(r);
    }

    [HttpPost]
    [Authorize(Roles = $"{Roles.Root},{Roles.Director}")]
    public async Task<ActionResult<RazaResponse>> Crear(RazaRequest req)
    {
        var error = await Validar(req, null);
        if (error != null) return error;

        var raza = new Raza { Nombre = req.Nombre.Trim(), EspecieId = req.EspecieId };
        db.Razas.Add(raza);
        await db.SaveChangesAsync();

        var especieNombre = await db.Especies.Where(e => e.Id == raza.EspecieId).Select(e => e.Nombre).FirstAsync();
        return CreatedAtAction(nameof(Obtener), new { id = raza.Id },
            new RazaResponse(raza.Id, raza.Nombre, raza.EspecieId, especieNombre));
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = $"{Roles.Root},{Roles.Director}")]
    public async Task<IActionResult> Editar(int id, RazaRequest req)
    {
        var raza = await db.Razas.FindAsync(id);
        if (raza == null) return NotFound(new { mensaje = "Raza no encontrada" });

        var error = await Validar(req, id);
        if (error != null) return error;

        raza.Nombre = req.Nombre.Trim();
        raza.EspecieId = req.EspecieId;
        await db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = $"{Roles.Root},{Roles.Director}")]
    public async Task<IActionResult> Eliminar(int id)
    {
        var raza = await db.Razas.FindAsync(id);
        if (raza == null) return NotFound(new { mensaje = "Raza no encontrada" });
        if (await db.Pacientes.AnyAsync(p => p.RazaId == id))
            return Conflict(new { mensaje = "No se puede eliminar: hay pacientes con esta raza" });

        db.Razas.Remove(raza);
        await db.SaveChangesAsync();
        return NoContent();
    }

    // Devuelve el error a responder, o null si todo está bien
    private async Task<ActionResult?> Validar(RazaRequest req, int? idActual)
    {
        if (string.IsNullOrWhiteSpace(req.Nombre)) return BadRequest(new { mensaje = "El nombre es obligatorio" });
        if (!await db.Especies.AnyAsync(e => e.Id == req.EspecieId))
            return BadRequest(new { mensaje = "La especie no existe" });
        if (await db.Razas.AnyAsync(r => r.Nombre == req.Nombre && r.EspecieId == req.EspecieId && r.Id != idActual))
            return Conflict(new { mensaje = "Esa raza ya existe en la especie" });
        return null;
    }
}