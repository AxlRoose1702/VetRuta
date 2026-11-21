using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VetRuta.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class DuenosPacientesVisitas : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AspNetUsers_Zonas_ZonaId",
                table: "AspNetUsers");

            migrationBuilder.DropForeignKey(
                name: "FK_Razas_Especies_EspecieId",
                table: "Razas");

            migrationBuilder.DropIndex(
                name: "IX_Razas_EspecieId",
                table: "Razas");

            migrationBuilder.AlterColumn<string>(
                name: "Nombre",
                table: "Zonas",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<string>(
                name: "Nombre",
                table: "Servicios",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<string>(
                name: "Nombre",
                table: "Razas",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<string>(
                name: "Nombre",
                table: "Especies",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<string>(
                name: "NombreCompleto",
                table: "AspNetUsers",
                type: "nvarchar(150)",
                maxLength: 150,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.CreateTable(
                name: "Dueños",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Nombre = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: false),
                    Telefono = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: true),
                    Direccion = table.Column<string>(type: "nvarchar(250)", maxLength: 250, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Dueños", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Pacientes",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Nombre = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    FechaNacimiento = table.Column<DateTime>(type: "datetime2", nullable: true),
                    RazaId = table.Column<int>(type: "int", nullable: false),
                    DuenoId = table.Column<int>(type: "int", nullable: false),
                    TecnicoId = table.Column<string>(type: "nvarchar(450)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Pacientes", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Pacientes_AspNetUsers_TecnicoId",
                        column: x => x.TecnicoId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Pacientes_Dueños_DuenoId",
                        column: x => x.DuenoId,
                        principalTable: "Dueños",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Pacientes_Razas_RazaId",
                        column: x => x.RazaId,
                        principalTable: "Razas",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Visitas",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PacienteId = table.Column<int>(type: "int", nullable: false),
                    ServicioId = table.Column<int>(type: "int", nullable: false),
                    TecnicoId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    FechaProgramada = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Estado = table.Column<int>(type: "int", nullable: false),
                    FechaRegistro = table.Column<DateTime>(type: "datetime2", nullable: true),
                    PesoKg = table.Column<decimal>(type: "decimal(6,2)", precision: 6, scale: 2, nullable: true),
                    AlturaCm = table.Column<decimal>(type: "decimal(6,2)", precision: 6, scale: 2, nullable: true),
                    Temperatura = table.Column<decimal>(type: "decimal(4,1)", precision: 4, scale: 1, nullable: true),
                    Condicion = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    Latitud = table.Column<double>(type: "float", nullable: true),
                    Longitud = table.Column<double>(type: "float", nullable: true),
                    FotoUrl = table.Column<string>(type: "nvarchar(300)", maxLength: 300, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Visitas", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Visitas_AspNetUsers_TecnicoId",
                        column: x => x.TecnicoId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Visitas_Pacientes_PacienteId",
                        column: x => x.PacienteId,
                        principalTable: "Pacientes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Visitas_Servicios_ServicioId",
                        column: x => x.ServicioId,
                        principalTable: "Servicios",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Zonas_Nombre",
                table: "Zonas",
                column: "Nombre",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Servicios_Nombre",
                table: "Servicios",
                column: "Nombre",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Razas_EspecieId_Nombre",
                table: "Razas",
                columns: new[] { "EspecieId", "Nombre" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Especies_Nombre",
                table: "Especies",
                column: "Nombre",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Pacientes_DuenoId",
                table: "Pacientes",
                column: "DuenoId");

            migrationBuilder.CreateIndex(
                name: "IX_Pacientes_RazaId",
                table: "Pacientes",
                column: "RazaId");

            migrationBuilder.CreateIndex(
                name: "IX_Pacientes_TecnicoId",
                table: "Pacientes",
                column: "TecnicoId");

            migrationBuilder.CreateIndex(
                name: "IX_Visitas_PacienteId",
                table: "Visitas",
                column: "PacienteId");

            migrationBuilder.CreateIndex(
                name: "IX_Visitas_ServicioId",
                table: "Visitas",
                column: "ServicioId");

            migrationBuilder.CreateIndex(
                name: "IX_Visitas_TecnicoId_FechaProgramada",
                table: "Visitas",
                columns: new[] { "TecnicoId", "FechaProgramada" });

            migrationBuilder.AddForeignKey(
                name: "FK_AspNetUsers_Zonas_ZonaId",
                table: "AspNetUsers",
                column: "ZonaId",
                principalTable: "Zonas",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Razas_Especies_EspecieId",
                table: "Razas",
                column: "EspecieId",
                principalTable: "Especies",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AspNetUsers_Zonas_ZonaId",
                table: "AspNetUsers");

            migrationBuilder.DropForeignKey(
                name: "FK_Razas_Especies_EspecieId",
                table: "Razas");

            migrationBuilder.DropTable(
                name: "Visitas");

            migrationBuilder.DropTable(
                name: "Pacientes");

            migrationBuilder.DropTable(
                name: "Dueños");

            migrationBuilder.DropIndex(
                name: "IX_Zonas_Nombre",
                table: "Zonas");

            migrationBuilder.DropIndex(
                name: "IX_Servicios_Nombre",
                table: "Servicios");

            migrationBuilder.DropIndex(
                name: "IX_Razas_EspecieId_Nombre",
                table: "Razas");

            migrationBuilder.DropIndex(
                name: "IX_Especies_Nombre",
                table: "Especies");

            migrationBuilder.AlterColumn<string>(
                name: "Nombre",
                table: "Zonas",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(100)",
                oldMaxLength: 100);

            migrationBuilder.AlterColumn<string>(
                name: "Nombre",
                table: "Servicios",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(100)",
                oldMaxLength: 100);

            migrationBuilder.AlterColumn<string>(
                name: "Nombre",
                table: "Razas",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(100)",
                oldMaxLength: 100);

            migrationBuilder.AlterColumn<string>(
                name: "Nombre",
                table: "Especies",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(100)",
                oldMaxLength: 100);

            migrationBuilder.AlterColumn<string>(
                name: "NombreCompleto",
                table: "AspNetUsers",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(150)",
                oldMaxLength: 150);

            migrationBuilder.CreateIndex(
                name: "IX_Razas_EspecieId",
                table: "Razas",
                column: "EspecieId");

            migrationBuilder.AddForeignKey(
                name: "FK_AspNetUsers_Zonas_ZonaId",
                table: "AspNetUsers",
                column: "ZonaId",
                principalTable: "Zonas",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Razas_Especies_EspecieId",
                table: "Razas",
                column: "EspecieId",
                principalTable: "Especies",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
