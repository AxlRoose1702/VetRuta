namespace VetRuta.Api.Dtos
{
    public class CatalogoDtos
    {
        public record ZonaRequest(string Nombre, string? Descripcion);
        public record ZonaResponse(int Id, string Nombre, string? Descripcion, bool Activo, int TotalTecnicos);

        public record EspecieRequest(string Nombre);
        public record EspecieResponse(int Id, string Nombre, int TotalRazas);

        public record RazaRequest(string Nombre, int EspecieId);
        public record RazaResponse(int Id, string Nombre, int EspecieId, string EspecieNombre);

        public record ServicioRequest(string Nombre, decimal Precio, int DuracionMinutos);
        public record ServicioResponse(int Id, string Nombre, decimal Precio, int DuracionMinutos);
    }
}
