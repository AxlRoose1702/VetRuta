namespace VetRuta.Domain.Entities
{
    public class Visita
    {
        public int Id { get; set; }
        public int PacienteId { get; set; }
        public Paciente? Paciente { get; set; }
        public int ServicioId { get; set; }
        public Servicio? Servicio { get; set; }
        public string TecnicoId { get; set; } = "";
        public DateTime FechaProgramada { get; set; }
        public EstadoVisita Estado { get; set; } = EstadoVisita.Programada;

        // Registro (se llena una sola vez)
        public DateTime? FechaRegistro { get; set; }
        public decimal? PesoKg { get; set; }
        public decimal? AlturaCm { get; set; }
        public decimal? Temperatura { get; set; }
        public string? Condicion { get; set; }
        public string? Observaciones { get; set; }
        public double? Latitud { get; set; }
        public double? Longitud { get; set; }
        public string? FotoUrl { get; set; }
    }
}
