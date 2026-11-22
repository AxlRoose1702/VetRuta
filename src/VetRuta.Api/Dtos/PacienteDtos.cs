namespace VetRuta.Api.Dtos;

public record DuenoRequest(string Nombre, string? Telefono, string? Direccion);
public record DuenoResponse(int Id, string Nombre, string? Telefono, string? Direccion, int TotalPacientes);

public record PacienteRequest(
    string Nombre,
    DateTime? FechaNacimiento,
    int RazaId,
    int DuenoId,
    string? TecnicoId,
    double? Latitud,
    double? Longitud);

public record ReasignarTecnicoRequest(string TecnicoId);

// Llega como multipart/form-data
public class FotoPacienteRequest
{
    public IFormFile? Foto { get; set; }
}

public record PacienteResponse(
    int Id,
    string Nombre,
    DateTime? FechaNacimiento,
    int RazaId,
    string RazaNombre,
    int EspecieId,
    string EspecieNombre,
    int DuenoId,
    string DuenoNombre,
    string? DuenoTelefono,
    string? TecnicoId,
    string? TecnicoNombre,
    string? FotoUrl,
    double? Latitud,
    double? Longitud);