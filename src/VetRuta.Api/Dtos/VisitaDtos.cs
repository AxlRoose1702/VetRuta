namespace VetRuta.Api.Dtos;

public record ProgramarVisitaRequest(int PacienteId, int ServicioId, DateTime FechaProgramada);
public record ReprogramarVisitaRequest(DateTime FechaProgramada);

// Llega como multipart/form-data por la foto
public class RegistrarVisitaRequest
{
    public decimal PesoKg { get; set; }
    public decimal AlturaCm { get; set; }
    public decimal Temperatura { get; set; }
    public string Condicion { get; set; } = "";
    public double Latitud { get; set; }
    public double Longitud { get; set; }
    public IFormFile? Foto { get; set; }
}

public record VisitaResponse
(
    int Id,
    int PacienteId, string PacienteNombre,
    string EspecieNombre, string DuenoNombre,
    int ServicioId, string ServicioNombre,
    string TecnicoId, string? TecnicoNombre,
    DateTime FechaProgramada,
    string Estado,
    bool Atrasada,
    DateTime? FechaRegistro,
    decimal? PesoKg, decimal? AlturaCm, decimal? Temperatura,
    string? Condicion,
    double? Latitud, double? Longitud,
    string? FotoUrl
);