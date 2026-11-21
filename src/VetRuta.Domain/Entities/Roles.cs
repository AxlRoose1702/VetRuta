namespace VetRuta.Domain.Entities
{
    public class Roles
    {
        public const string Root = "Root";
        public const string Director = "Director";
        public const string Medico = "Medico";
        public const string Tecnico = "Tecnico";
        public static readonly string[] Todos = { Root, Director, Medico, Tecnico };
    }
}
