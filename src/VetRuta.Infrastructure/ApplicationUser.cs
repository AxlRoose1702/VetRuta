using Microsoft.AspNetCore.Identity;
using VetRuta.Domain.Entities;

namespace VetRuta.Infrastructure.Identity;

public class ApplicationUser : IdentityUser
{
    public string NombreCompleto { get; set; } = string.Empty;
    public bool Activo { get; set; } = true;

    public string? MedicoId { get; set; }
    public ApplicationUser? Medico { get; set; }
    public ICollection<ApplicationUser> Tecnicos { get; set; } = new List<ApplicationUser>();

    public int? ZonaId { get; set; }
    public Zona? Zona { get; set; }
}