using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using VetRuta.Api.Services;
using VetRuta.Infrastructure.Identity;
using static VetRuta.Api.Dtos.AuthDtos;

namespace VetRuta.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController(UserManager<ApplicationUser> userManager, TokenService tokenService) : ControllerBase
{
    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<ActionResult<LoginResponse>> Login(LoginRequest req)
    {
        var user = await userManager.FindByEmailAsync(req.Email);
        if (user == null || !await userManager.CheckPasswordAsync(user, req.Password))
            return Unauthorized(new { mensaje = "Credenciales inválidas" });

        if (!user.Activo)
            return Unauthorized(new { mensaje = "Usuario desactivado" });

        var roles = await userManager.GetRolesAsync(user);
        var (token, expira) = tokenService.Crear(user, roles);

        return Ok(new LoginResponse(token, expira, user.Id, user.NombreCompleto, roles.FirstOrDefault() ?? ""));
    }

    [HttpGet("me")]
    [Authorize]
    public IActionResult Me() => Ok(new
    {
        Id = User.FindFirstValue(ClaimTypes.NameIdentifier),
        Nombre = User.FindFirstValue(ClaimTypes.Name),
        Email = User.FindFirstValue(ClaimTypes.Email),
        Roles = User.FindAll(ClaimTypes.Role).Select(c => c.Value)
    });
}