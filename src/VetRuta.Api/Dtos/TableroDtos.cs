namespace VetRuta.Api.Dtos;

public record HistorialPacienteResponse(
    PacienteResponse Paciente,
    int TotalVisitas,
    int Realizadas,
    DateTime? UltimaVisita,
    IEnumerable<VisitaResponse> Visitas);

public record ResumenVisitas(int Programadas, int Realizadas, int Canceladas, int Atrasadas, decimal PorcentajeCumplimiento);
public record CumplimientoTecnico(string TecnicoId, string TecnicoNombre, int Realizadas, int Vencidas, decimal PorcentajeCumplimiento);
public record PacientesPorEspecie(string Especie, int Total);

public record TableroResponse(
    DateTime Desde,
    DateTime Hasta,
    ResumenVisitas Resumen,
    IEnumerable<CumplimientoTecnico> PorTecnico,
    IEnumerable<PacientesPorEspecie> PorEspecie);