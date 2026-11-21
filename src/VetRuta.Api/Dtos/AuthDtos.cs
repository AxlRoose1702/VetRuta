namespace VetRuta.Api.Dtos
{
    public class AuthDtos
    {
        public record LoginRequest(string Email, string Password);
        public record LoginResponse(string Token, DateTime Expira, string UsuarioId, string Nombre, string Rol);
    }
}
