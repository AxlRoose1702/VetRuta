using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using VetRuta.Domain.Entities;
using VetRuta.Infrastructure.Identity;

namespace VetRuta.Infrastructure.Data;

public static class DbSeeder
{
    public static async Task SeedAsync(IServiceProvider sp)
    {
        using var scope = sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var roleMgr = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();
        var userMgr = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();

        await db.Database.MigrateAsync();

        foreach (var r in Roles.Todos)
            if (!await roleMgr.RoleExistsAsync(r))
                await roleMgr.CreateAsync(new IdentityRole(r));

        if (await userMgr.FindByNameAsync("root") is null)
        {
            var root = new ApplicationUser { UserName = "root", Email = "root@vetruta.com", NombreCompleto = "Administrador", EmailConfirmed = true };
            await userMgr.CreateAsync(root, "Root123!");
            await userMgr.AddToRoleAsync(root, Roles.Root);
        }

        if (!db.Zonas.Any())
            db.Zonas.AddRange(new Zona { Nombre = "Zona 1" }, new Zona { Nombre = "Zona 10" }, new Zona { Nombre = "Mixco" });

        if (!db.Especies.Any())
            db.Especies.AddRange(
                new Especie { Nombre = "Perro", Razas = { new() { Nombre = "Labrador" }, new() { Nombre = "Pastor Alemán" }, new() { Nombre = "Mestizo" } } },
                new Especie { Nombre = "Gato", Razas = { new() { Nombre = "Siamés" }, new() { Nombre = "Persa" }, new() { Nombre = "Mestizo" } } },
                new Especie { Nombre = "Ave", Razas = { new() { Nombre = "Perico" }, new() { Nombre = "Canario" } } },
                new Especie { Nombre = "Conejo", Razas = { new() { Nombre = "Holland Lop" }, new() { Nombre = "Rex" } } },
                new Especie { Nombre = "Reptil", Razas = { new() { Nombre = "Iguana" }, new() { Nombre = "Tortuga" } } });

        if (!db.Servicios.Any())
            db.Servicios.AddRange(
                new Servicio { Nombre = "Control de peso", Precio = 75, DuracionMinutos = 20 },
                new Servicio { Nombre = "Vacunación", Precio = 150, DuracionMinutos = 30 },
                new Servicio { Nombre = "Desparasitación", Precio = 100, DuracionMinutos = 20 },
                new Servicio { Nombre = "Curación de heridas", Precio = 200, DuracionMinutos = 45 },
                new Servicio { Nombre = "Control postoperatorio", Precio = 250, DuracionMinutos = 40 });

        await db.SaveChangesAsync();
    }
}