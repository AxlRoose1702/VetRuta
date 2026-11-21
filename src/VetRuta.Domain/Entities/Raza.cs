namespace VetRuta.Domain.Entities
{
    public class Raza
    {
        public int Id { get; set; }
        public string Nombre { get; set; } = ""; 
        public int EspecieId { get; set; }
        public Especie? Especie { get; set; }
    }
}
