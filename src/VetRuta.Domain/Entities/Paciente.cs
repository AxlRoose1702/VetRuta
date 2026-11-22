namespace VetRuta.Domain.Entities
{
    public class Paciente
    {
        public int Id { get; set; }
        public string Nombre { get; set; } = "";
        public DateTime? FechaNacimiento { get; set; }
        public int RazaId { get; set; }
        public Raza? Raza { get; set; }
        public int DuenoId { get; set; }
        public Duenio? Dueno { get; set; }
        public string? TecnicoId { get; set; }   // Id del ApplicationUser
        public string? FotoUrl { get; set; }     // foto de la mascota
        public double? Latitud { get; set; }     // ubicación de la casa, para el mapa
        public double? Longitud { get; set; }
        public ICollection<Visita> Visitas { get; set; } = new List<Visita>();

    }
}
