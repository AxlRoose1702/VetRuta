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
public class ServiciosController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<ServicioResponse>>> Listar() =>
        Ok(await db.Servicios
            .OrderBy(s => s.Nombre)
            .Select(s => new ServicioResponse(s.Id, s.Nombre, s.Precio, s.DuracionMinutos))
            .ToListAsync());

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ServicioResponse>> Obtener(int id)
    {
        var s = await db.Servicios.FindAsync(id);
        return s == null ? NotFound(new { mensaje = "Servicio no encontrado" })
                         : Ok(new ServicioResponse(s.Id, s.Nombre, s.Precio, s.DuracionMinutos));
    }

    [HttpPost]
    [Authorize(Roles = $"{Roles.Root},{Roles.Director}")]
    public async Task<ActionResult<ServicioResponse>> Crear(ServicioRequest req)
    {
        var error = await Validar(req, null);
        if (error != null) return error;

        var s = new Servicio { Nombre = req.Nombre.Trim(), Precio = req.Precio, DuracionMinutos = req.DuracionMinutos };
        db.Servicios.Add(s);
        await db.SaveChangesAsync();
        return CreatedAtAction(nameof(Obtener), new { id = s.Id },
            new ServicioResponse(s.Id, s.Nombre, s.Precio, s.DuracionMinutos));
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = $"{Roles.Root},{Roles.Director}")]
    public async Task<IActionResult> Editar(int id, ServicioRequest req)
    {
        var s = await db.Servicios.FindAsync(id);
        if (s == null) return NotFound(new { mensaje = "Servicio no encontrado" });

        var error = await Validar(req, id);
        if (error != null) return error;

        s.Nombre = req.Nombre.Trim();
        s.Precio = req.Precio;
        s.DuracionMinutos = req.DuracionMinutos;
        await db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = $"{Roles.Root},{Roles.Director}")]
    public async Task<IActionResult> Eliminar(int id)
    {
        var s = await db.Servicios.FindAsync(id);
        if (s == null) return NotFound(new { mensaje = "Servicio no encontrado" });
        if (await db.Visitas.AnyAsync(v => v.ServicioId == id))
            return Conflict(new { mensaje = "No se puede eliminar: el servicio tiene visitas" });

        db.Servicios.Remove(s);
        await db.SaveChangesAsync();
        return NoContent();
    }

    private async Task<ActionResult?> Validar(ServicioRequest req, int? idActual)
    {
        if (string.IsNullOrWhiteSpace(req.Nombre)) return BadRequest(new { mensaje = "El nombre es obligatorio" });
        if (req.Precio < 0) return BadRequest(new { mensaje = "El precio no puede ser negativo" });
        if (req.DuracionMinutos <= 0) return BadRequest(new { mensaje = "La duración debe ser mayor a 0" });
        if (await db.Servicios.AnyAsync(s => s.Nombre == req.Nombre && s.Id != idActual))
            return Conflict(new { mensaje = "Ya existe un servicio con ese nombre" });
        return null;
    }
}