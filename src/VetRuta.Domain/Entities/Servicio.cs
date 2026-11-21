namespace VetRuta.Domain.Entities
{
    public class Servicio
    {
        public int Id { get; set; }
        public string Nombre { get; set; } = ""; 
        public decimal Precio { get; set; }
        public int DuracionMinutos { get; set; }
    }

    public enum EstadoVisita
    {
        Programada = 0, 
        Realizada = 1, 
        Cancelada = 2
    }
}
