namespace VetRuta.Domain.Entities
{
    public class Especie
    {
        public int Id { get; set; }
        public string Nombre { get; set; } = ""; 
        public ICollection<Raza> Razas { get; set; } = new List<Raza>();
    }
}
