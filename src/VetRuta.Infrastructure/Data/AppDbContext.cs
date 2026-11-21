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
    public DbSet<Paciente> Pacientes => Set<Paciente>();
    public DbSet<Visita> Visitas => Set<Visita>();
    public DbSet<Duenio> Dueños => Set<Duenio>();

    protected override void OnModelCreating(ModelBuilder b)
    {
        base.OnModelCreating(b);

        // Usuario: técnico -> médico (se relaciona consigo misma) y zona
        b.Entity<ApplicationUser>(e =>
        {
            e.Property(u => u.NombreCompleto).HasMaxLength(150);
            e.HasOne(u => u.Medico).WithMany(m => m.Tecnicos)
                .HasForeignKey(u => u.MedicoId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(u => u.Zona).WithMany()
                .HasForeignKey(u => u.ZonaId).OnDelete(DeleteBehavior.SetNull);
        });

        b.Entity<Zona>(e =>
        {
            e.Property(z => z.Nombre).HasMaxLength(100).IsRequired();
            e.HasIndex(z => z.Nombre).IsUnique();
        });

        b.Entity<Especie>(e =>
        {
            e.Property(x => x.Nombre).HasMaxLength(100).IsRequired();
            e.HasIndex(x => x.Nombre).IsUnique();
        });

        b.Entity<Raza>(e =>
        {
            e.Property(x => x.Nombre).HasMaxLength(100).IsRequired();
            e.HasOne(r => r.Especie).WithMany(s => s.Razas)
                .HasForeignKey(r => r.EspecieId).OnDelete(DeleteBehavior.Restrict);
            e.HasIndex(r => new { r.EspecieId, r.Nombre }).IsUnique();
        });

        b.Entity<Servicio>(e =>
        {
            e.Property(x => x.Nombre).HasMaxLength(100).IsRequired();
            e.Property(x => x.Precio).HasPrecision(10, 2);
            e.HasIndex(x => x.Nombre).IsUnique();
        });

        b.Entity<Duenio>(e =>
        {
            e.Property(x => x.Nombre).HasMaxLength(150).IsRequired();
            e.Property(x => x.Telefono).HasMaxLength(20);
            e.Property(x => x.Direccion).HasMaxLength(250);
        });

        b.Entity<Paciente>(e =>
        {
            e.Property(x => x.Nombre).HasMaxLength(100).IsRequired();
            e.HasOne(p => p.Raza).WithMany()
                .HasForeignKey(p => p.RazaId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(p => p.Duenio).WithMany(d => d.Pacientes)
                .HasForeignKey(p => p.DuenoId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne<ApplicationUser>().WithMany()
                .HasForeignKey(p => p.TecnicoId).OnDelete(DeleteBehavior.Restrict);
        });

        b.Entity<Visita>(e =>
        {
            e.Property(x => x.PesoKg).HasPrecision(6, 2);
            e.Property(x => x.AlturaCm).HasPrecision(6, 2);
            e.Property(x => x.Temperatura).HasPrecision(4, 1);
            e.Property(x => x.Condicion).HasMaxLength(500);
            e.Property(x => x.FotoUrl).HasMaxLength(300);
            e.HasOne(v => v.Paciente).WithMany(p => p.Visitas)
                .HasForeignKey(v => v.PacienteId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(v => v.Servicio).WithMany()
                .HasForeignKey(v => v.ServicioId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne<ApplicationUser>().WithMany()
                .HasForeignKey(v => v.TecnicoId).OnDelete(DeleteBehavior.Restrict);
            e.HasIndex(v => new { v.TecnicoId, v.FechaProgramada });
        });
    }
}