using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VetRuta.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class FotoObservacionesUbicacion : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Observaciones",
                table: "Visitas",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "FotoUrl",
                table: "Pacientes",
                type: "nvarchar(300)",
                maxLength: 300,
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "Latitud",
                table: "Pacientes",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "Longitud",
                table: "Pacientes",
                type: "float",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Observaciones",
                table: "Visitas");

            migrationBuilder.DropColumn(
                name: "FotoUrl",
                table: "Pacientes");

            migrationBuilder.DropColumn(
                name: "Latitud",
                table: "Pacientes");

            migrationBuilder.DropColumn(
                name: "Longitud",
                table: "Pacientes");
        }
    }
}
