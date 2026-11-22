using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using VetRuta.Api.Dtos;
using VetRuta.Domain.Entities;
using VetRuta.Infrastructure.Data;
using VetRuta.Infrastructure.Identity;

namespace VetRuta.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UsuariosController(UserManager<ApplicationUser> userManager, AppDbContext db) : ControllerBase
{
    private string UsuarioActualId => User.FindFirstValue(ClaimTypes.NameIdentifier)!;

    // GET api/usuarios?rol=Tecnico&activo=true
    [HttpGet]
    [Authorize(Roles = $"{Roles.Root},{Roles.Director}")]
    public async Task<ActionResult<IEnumerable<UsuarioResponse>>> Listar([FromQuery] string? rol, [FromQuery] bool? activo)
    {
        IList<ApplicationUser> usuarios;
        if (!string.IsNullOrWhiteSpace(rol))
        {
            if (!Roles.Todos.Contains(rol)) return BadRequest(new { mensaje = "Rol inválido" });
            usuarios = await userManager.GetUsersInRoleAsync(rol);
        }
        else
        {
            usuarios = await userManager.Users.ToListAsync();
        }

        // El Director no ve usuarios Root
        if (User.IsInRole(Roles.Director))
        {
            var roots = await userManager.GetUsersInRoleAsync(Roles.Root);
            var rootIds = roots.Select(r => r.Id).ToHashSet();
            usuarios = usuarios.Where(u => !rootIds.Contains(u.Id)).ToList();
        }

        if (activo.HasValue) usuarios = usuarios.Where(u => u.Activo == activo.Value).ToList();

        var resultado = new List<UsuarioResponse>();
        foreach (var u in usuarios.OrderBy(u => u.NombreCompleto))
            resultado.Add(await MapearAsync(u));
        return Ok(resultado);
    }

    // GET api/usuarios/{id}
    [HttpGet("{id}")]
    [Authorize(Roles = $"{Roles.Root},{Roles.Director}")]
    public async Task<ActionResult<UsuarioResponse>> Obtener(string id)
    {
        var user = await userManager.FindByIdAsync(id);
        if (user == null) return NotFound(new { mensaje = "Usuario no encontrado" });
        return Ok(await MapearAsync(user));
    }

    // GET api/usuarios/medicos/{medicoId}/tecnicos
    [HttpGet("medicos/{medicoId}/tecnicos")]
    [Authorize(Roles = $"{Roles.Root},{Roles.Director},{Roles.Medico}")]
    public async Task<ActionResult<IEnumerable<UsuarioResponse>>> TecnicosDeMedico(string medicoId)
    {
        // Un médico solo puede ver a sus propios técnicos
        if (User.IsInRole(Roles.Medico) && medicoId != UsuarioActualId) return Forbid();

        var tecnicos = await userManager.Users
            .Where(u => u.MedicoId == medicoId)
            .OrderBy(u => u.NombreCompleto)
            .ToListAsync();

        var resultado = new List<UsuarioResponse>();
        foreach (var t in tecnicos) resultado.Add(await MapearAsync(t));
        return Ok(resultado);
    }

    // POST api/usuarios
    [HttpPost]
    [Authorize(Roles = Roles.Root)]
    public async Task<ActionResult<UsuarioResponse>> Crear(CrearUsuarioRequest req)
    {

        if (!Roles.Todos.Contains(req.Rol)) return BadRequest(new { mensaje = "Rol inválido" });
        if (await userManager.FindByEmailAsync(req.Email) != null)
            return Conflict(new { mensaje = "Ya existe un usuario con ese correo" });
        if (req.ZonaId.HasValue && !await db.Zonas.AnyAsync(z => z.Id == req.ZonaId))
            return BadRequest(new { mensaje = "La zona no existe" });

        var user = new ApplicationUser
        {
            UserName = req.Email,
            Email = req.Email,
            NombreCompleto = req.NombreCompleto,
            ZonaId = req.ZonaId,
            Activo = true
        };

        var crear = await userManager.CreateAsync(user, req.Password);
        if (!crear.Succeeded) return BadRequest(new { errores = crear.Errors.Select(e => e.Description) });

        var rol = await userManager.AddToRoleAsync(user, req.Rol);
        if (!rol.Succeeded)
        {
            await userManager.DeleteAsync(user);
            return BadRequest(new { errores = rol.Errors.Select(e => e.Description) });
        }

        return CreatedAtAction(nameof(Obtener), new { id = user.Id }, await MapearAsync(user));

    }

    // PUT api/usuarios/{id}
    [HttpPut("{id}")]
    [Authorize(Roles = Roles.Root)]
    public async Task<ActionResult<UsuarioResponse>> Editar(string id, EditarUsuarioRequest req)
    {
        var user = await userManager.FindByIdAsync(id);
        if (user == null) return NotFound(new { mensaje = "Usuario no encontrado" });

        // si 
        if (!string.Equals(user.Email, req.Email, StringComparison.OrdinalIgnoreCase))
        {
            var otro = await userManager.FindByEmailAsync(req.Email);
            if (otro != null && otro.Id != user.Id)
                return Conflict(new { mensaje = "Ya existe un usuario con ese correo" });
            user.Email = req.Email;
            user.UserName = req.Email;
        }

        if (req.ZonaId.HasValue && !await db.Zonas.AnyAsync(z => z.Id == req.ZonaId))
            return BadRequest(new { mensaje = "La zona no existe" });

        user.NombreCompleto = req.NombreCompleto;
        user.ZonaId = req.ZonaId;

        var res = await userManager.UpdateAsync(user);
        if (!res.Succeeded) return BadRequest(new { errores = res.Errors.Select(e => e.Description) });

        return Ok(await MapearAsync(user));
    }

    // PUT api/usuarios/{id}/medico  -> asigna un técnico a un médico
    [HttpPut("{id}/medico")]
    [Authorize(Roles = $"{Roles.Root},{Roles.Director}")]
    public async Task<ActionResult<UsuarioResponse>> AsignarMedico(string id, AsignarMedicoRequest req)
    {
        var tecnico = await userManager.FindByIdAsync(id);
        if (tecnico == null) return NotFound(new { mensaje = "Técnico no encontrado" });
        if (!await userManager.IsInRoleAsync(tecnico, Roles.Tecnico))
            return BadRequest(new { mensaje = "Solo se puede asignar médico a un técnico" });

        var medico = await userManager.FindByIdAsync(req.MedicoId);
        if (medico == null || !await userManager.IsInRoleAsync(medico, Roles.Medico))
            return BadRequest(new { mensaje = "El médico no existe" });
        if (!medico.Activo) return BadRequest(new { mensaje = "El médico está desactivado" });

        tecnico.MedicoId = medico.Id; // un técnico pertenece a un solo médico
        var res = await userManager.UpdateAsync(tecnico);
        if (!res.Succeeded) return BadRequest(new { errores = res.Errors.Select(e => e.Description) });

        return Ok(await MapearAsync(tecnico));
    }

    // DELETE api/usuarios/{id}/medico  -> quita el médico al técnico
    [HttpDelete("{id}/medico")]
    [Authorize(Roles = $"{Roles.Root},{Roles.Director}")]
    public async Task<ActionResult<UsuarioResponse>> QuitarMedico(string id)
    {
        var tecnico = await userManager.FindByIdAsync(id);
        if (tecnico == null) return NotFound(new { mensaje = "Técnico no encontrado" });

        tecnico.MedicoId = null;
        var res = await userManager.UpdateAsync(tecnico);
        if (!res.Succeeded) return BadRequest(new { errores = res.Errors.Select(e => e.Description) });

        return Ok(await MapearAsync(tecnico));
    }

    // PATCH api/usuarios/{id}/activar
    [HttpPatch("{id}/activar")]
    [Authorize(Roles = Roles.Root)]
    public Task<IActionResult> Activar(string id) => CambiarEstadoAsync(id, true);

    // PATCH api/usuarios/{id}/desactivar
    [HttpPatch("{id}/desactivar")]
    [Authorize(Roles = Roles.Root)]
    public Task<IActionResult> Desactivar(string id) => CambiarEstadoAsync(id, false);

    // PUT api/usuarios/{id}/password
    [HttpPut("{id}/password")]
    [Authorize(Roles = Roles.Root)]
    public async Task<IActionResult> CambiarPassword(string id, CambiarPasswordRequest req)
    {
        var user = await userManager.FindByIdAsync(id);
        if (user == null) return NotFound(new { mensaje = "Usuario no encontrado" });

        var token = await userManager.GeneratePasswordResetTokenAsync(user);
        var res = await userManager.ResetPasswordAsync(user, token, req.NuevaPassword);
        if (!res.Succeeded) return BadRequest(new { errores = res.Errors.Select(e => e.Description) });
        return NoContent();
    }

    // ---------- privados ----------

    private async Task<IActionResult> CambiarEstadoAsync(string id, bool activo)
    {
        if (id == UsuarioActualId) return BadRequest(new { mensaje = "No puedes cambiar tu propio estado" });

        var user = await userManager.FindByIdAsync(id);
        if (user == null) return NotFound(new { mensaje = "Usuario no encontrado" });

        user.Activo = activo;
        await userManager.UpdateAsync(user);
        return NoContent();
    }

    //private async Task<string?> ValidarZonaYMedicoAsync(int? zonaId, string? medicoId, string rol)
    //{
    //    if (zonaId.HasValue && !await db.Zonas.AnyAsync(z => z.Id == zonaId))
    //        return "La zona no existe";

    //    if (rol == Roles.Tecnico && !string.IsNullOrEmpty(medicoId))
    //    {
    //        var medico = await userManager.FindByIdAsync(medicoId);
    //        if (medico == null || !await userManager.IsInRoleAsync(medico, Roles.Medico))
    //            return "El médico no existe";
    //    }
    //    return null;
    //}

    private async Task<UsuarioResponse> MapearAsync(ApplicationUser u)
    {
        var roles = await userManager.GetRolesAsync(u);
        string? zonaNombre = u.ZonaId.HasValue
            ? await db.Zonas.Where(z => z.Id == u.ZonaId).Select(z => z.Nombre).FirstOrDefaultAsync()
            : null;
        string? medicoNombre = u.MedicoId != null
            ? await userManager.Users.Where(m => m.Id == u.MedicoId).Select(m => m.NombreCompleto).FirstOrDefaultAsync()
            : null;

        return new UsuarioResponse(u.Id, u.Email ?? "", u.NombreCompleto, roles.FirstOrDefault() ?? "",
            u.Activo, u.ZonaId, zonaNombre, u.MedicoId, medicoNombre);
    }
}