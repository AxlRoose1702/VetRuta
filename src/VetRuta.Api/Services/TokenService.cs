using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;
using VetRuta.Api.Settings;
using VetRuta.Infrastructure.Identity;

namespace VetRuta.Api.Services;

public class TokenService(IOptions<JwtSettings> options)
{
    private readonly JwtSettings _jwt = options.Value;

    public (string token, DateTime expira) Crear(ApplicationUser user, IList<string> roles)
    {
        var expira = DateTime.UtcNow.AddMinutes(_jwt.ExpiraMinutos);

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.Id),
            new(ClaimTypes.Email, user.Email ?? ""),
            new(ClaimTypes.Name, user.NombreCompleto),
        };
        claims.AddRange(roles.Select(r => new Claim(ClaimTypes.Role, r)));
        if (user.MedicoId != null) claims.Add(new Claim("medicoId", user.MedicoId));
        if (user.ZonaId != null) claims.Add(new Claim("zonaId", user.ZonaId.Value.ToString()));

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwt.Key));
        var descriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = expira,
            Issuer = _jwt.Issuer,
            Audience = _jwt.Audience,
            SigningCredentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256)
        };

        return (new JsonWebTokenHandler().CreateToken(descriptor), expira);
    }
}