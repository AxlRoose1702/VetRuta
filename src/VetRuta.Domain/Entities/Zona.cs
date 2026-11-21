namespace VetRuta.Domain.Entities
{
    public class Zona
    {
        public int Id { get; set; }
        public string Nombre { get; set; } = "";
        public string? Descripcion { get; set; }
        public bool Activo { get; set; } = true;
    }
}
