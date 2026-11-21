namespace VetRuta.Api.Dtos;

// El record sirve para definir un DTO (Data Transfer Object) que representa la información de un usuario en la aplicación.
public record CrearUsuarioRequest(
    string Email,
    string Password,
    string NombreCompleto,
    string Rol,
    int? ZonaId,
    string? MedicoId
    );

public record EditarUsuarioRequest(
    string Email,
    string NombreCompleto,
    int? ZonaId
    );

public record AsignarMedicoRequest(string MedicoId);

public record CambiarPasswordRequest(string NuevaPassword);

public record UsuarioResponse(
    string Id,
    string Email,
    string NombreCompleto,
    string Rol,
    bool Activo,
    int? ZonaId,
    string? ZonaNombre,
    string? MedicoId,
    string? MedicoNombre
    );