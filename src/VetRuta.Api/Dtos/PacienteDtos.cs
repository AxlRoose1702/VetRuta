namespace VetRuta.Api.Dtos;

public record DuenoRequest(string Nombre, string? Telefono, string? Direccion);
public record DuenoResponse(int Id, string Nombre, string? Telefono, string? Direccion, int TotalPacientes);

public record PacienteRequest(string Nombre, DateTime? FechaNacimiento, int RazaId, int DuenoId, string? TecnicoId);
public record ReasignarTecnicoRequest(string TecnicoId);

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
    string? TecnicoNombre);