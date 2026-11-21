using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using VetRuta.Domain.Entities;
using VetRuta.Infrastructure.Identity;

namespace VetRuta.Infrastructure.Data;

public class AppDbContext : IdentityDbContext<ApplicationUser>
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Zona> Zonas => Set<Zona>();
    public DbSet<Especie> Especies => Set<Especie>();
    public DbSet<Raza> Razas => Set<Raza>();
    public DbSet<Servicio> Servicios => Set<Servicio>();

    protected override void OnModelCreating(ModelBuilder b)
    {
        base.OnModelCreating(b);
        b.Entity<Servicio>().Property(s => s.Precio).HasPrecision(10, 2);
        b.Entity<ApplicationUser>()
            .HasOne(u => u.Medico).WithMany(m => m.Tecnicos)
            .HasForeignKey(u => u.MedicoId).OnDelete(DeleteBehavior.Restrict);
    }
}