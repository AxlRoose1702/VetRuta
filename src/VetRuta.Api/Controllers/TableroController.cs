using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using VetRuta.Api.Dtos;
using VetRuta.Domain.Entities;
using VetRuta.Infrastructure.Data;

namespace VetRuta.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = $"{Roles.Director},{Roles.Medico},{Roles.Tecnico}")]
public class TableroController(AppDbContext db) : ControllerBase
{
    private string UsuarioActualId => User.FindFirstValue(ClaimTypes.NameIdentifier)!;

    // GET api/tablero?desde=2026-11-01&hasta=2026-11-30
    [HttpGet]
    public async Task<ActionResult<TableroResponse>> Obtener([FromQuery] DateTime? desde, [FromQuery] DateTime? hasta)
    {
        var hoy = DateTime.UtcNow;
        var inicio = (desde ?? new DateTime(hoy.Year, hoy.Month, 1)).Date;
        var fin = (hasta ?? inicio.AddMonths(1).AddDays(-1)).Date;
        if (fin < inicio) return BadRequest(new { mensaje = "La fecha final no puede ser menor que la inicial" });
        var finExclusivo = fin.AddDays(1);

        var visitas = VisitasVisibles()
            .Where(v => v.FechaProgramada >= inicio && v.FechaProgramada < finExclusivo);

        // 1. Realizadas contra programadas
        var conteos = await visitas
            .GroupBy(v => 1)
            .Select(g => new
            {
                Programadas = g.Count(v => v.Estado == EstadoVisita.Programada),
                Realizadas = g.Count(v => v.Estado == EstadoVisita.Realizada),
                Canceladas = g.Count(v => v.Estado == EstadoVisita.Cancelada),
                Atrasadas = g.Count(v => v.Estado == EstadoVisita.Programada && v.FechaProgramada < hoy)
            })
            .FirstOrDefaultAsync();

        var resumen = conteos == null
            ? new ResumenVisitas(0, 0, 0, 0, 0)
            : new ResumenVisitas(conteos.Programadas, conteos.Realizadas, conteos.Canceladas, conteos.Atrasadas,
                Porcentaje(conteos.Realizadas, conteos.Atrasadas));

        // 2. Cumplimiento por técnico
        var porTecnicoBd = await visitas
            .Where(v => v.Estado != EstadoVisita.Cancelada)
            .GroupBy(v => v.TecnicoId)
            .Select(g => new
            {
                TecnicoId = g.Key,
                Realizadas = g.Count(v => v.Estado == EstadoVisita.Realizada),
                Vencidas = g.Count(v => v.Estado == EstadoVisita.Programada && v.FechaProgramada < hoy)
            })
            .ToListAsync();

        var ids = porTecnicoBd.Select(t => t.TecnicoId).ToList();
        var nombres = await db.Users.Where(u => ids.Contains(u.Id))
            .ToDictionaryAsync(u => u.Id, u => u.NombreCompleto);

        var porTecnico = porTecnicoBd
            .Select(t => new CumplimientoTecnico(
                t.TecnicoId,
                nombres.GetValueOrDefault(t.TecnicoId, "(sin nombre)"),
                t.Realizadas,
                t.Vencidas,
                Porcentaje(t.Realizadas, t.Vencidas)))
            .OrderByDescending(t => t.PorcentajeCumplimiento)
            .ToList();

        // 3. Pacientes por especie (no depende de fechas)
        var porEspecie = (await PacientesVisibles()
                .GroupBy(p => p.Raza!.Especie!.Nombre)
                .Select(g => new { Especie = g.Key, Total = g.Count() })
                .OrderByDescending(x => x.Total)
                .ToListAsync())
            .Select(x => new PacientesPorEspecie(x.Especie, x.Total))
            .ToList();

        return Ok(new TableroResponse(inicio, fin, resumen, porTecnico, porEspecie));
    }

    // ---------- privados ----------

    // realizadas / (realizadas + vencidas sin hacer), con 1 decimal
    private static decimal Porcentaje(int realizadas, int vencidas)
    {
        var total = realizadas + vencidas;
        return total == 0 ? 0 : Math.Round(realizadas * 100m / total, 1);
    }

    private IQueryable<Visita> VisitasVisibles()
    {
        var yo = UsuarioActualId;
        if (User.IsInRole(Roles.Tecnico)) return db.Visitas.Where(v => v.TecnicoId == yo);
        if (User.IsInRole(Roles.Medico))
            return db.Visitas.Where(v => db.Users.Any(u => u.Id == v.TecnicoId && u.MedicoId == yo));
        return db.Visitas;
    }

    private IQueryable<Paciente> PacientesVisibles()
    {
        var yo = UsuarioActualId;
        if (User.IsInRole(Roles.Tecnico)) return db.Pacientes.Where(p => p.TecnicoId == yo);
        if (User.IsInRole(Roles.Medico))
            return db.Pacientes.Where(p => db.Users.Any(u => u.Id == p.TecnicoId && u.MedicoId == yo));
        return db.Pacientes;
    }
}