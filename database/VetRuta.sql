IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

BEGIN TRANSACTION;
CREATE TABLE [AspNetRoles] (
    [Id] nvarchar(450) NOT NULL,
    [Name] nvarchar(256) NULL,
    [NormalizedName] nvarchar(256) NULL,
    [ConcurrencyStamp] nvarchar(max) NULL,
    CONSTRAINT [PK_AspNetRoles] PRIMARY KEY ([Id])
);

CREATE TABLE [Especies] (
    [Id] int NOT NULL IDENTITY,
    [Nombre] nvarchar(max) NOT NULL,
    CONSTRAINT [PK_Especies] PRIMARY KEY ([Id])
);

CREATE TABLE [Servicios] (
    [Id] int NOT NULL IDENTITY,
    [Nombre] nvarchar(max) NOT NULL,
    [Precio] decimal(10,2) NOT NULL,
    [DuracionMinutos] int NOT NULL,
    CONSTRAINT [PK_Servicios] PRIMARY KEY ([Id])
);

CREATE TABLE [Zonas] (
    [Id] int NOT NULL IDENTITY,
    [Nombre] nvarchar(max) NOT NULL,
    [Descripcion] nvarchar(max) NULL,
    [Activo] bit NOT NULL,
    CONSTRAINT [PK_Zonas] PRIMARY KEY ([Id])
);

CREATE TABLE [AspNetRoleClaims] (
    [Id] int NOT NULL IDENTITY,
    [RoleId] nvarchar(450) NOT NULL,
    [ClaimType] nvarchar(max) NULL,
    [ClaimValue] nvarchar(max) NULL,
    CONSTRAINT [PK_AspNetRoleClaims] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_AspNetRoleClaims_AspNetRoles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [AspNetRoles] ([Id]) ON DELETE CASCADE
);

CREATE TABLE [Razas] (
    [Id] int NOT NULL IDENTITY,
    [Nombre] nvarchar(max) NOT NULL,
    [EspecieId] int NOT NULL,
    CONSTRAINT [PK_Razas] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Razas_Especies_EspecieId] FOREIGN KEY ([EspecieId]) REFERENCES [Especies] ([Id]) ON DELETE CASCADE
);

CREATE TABLE [AspNetUsers] (
    [Id] nvarchar(450) NOT NULL,
    [NombreCompleto] nvarchar(max) NOT NULL,
    [Activo] bit NOT NULL,
    [MedicoId] nvarchar(450) NULL,
    [ZonaId] int NULL,
    [UserName] nvarchar(256) NULL,
    [NormalizedUserName] nvarchar(256) NULL,
    [Email] nvarchar(256) NULL,
    [NormalizedEmail] nvarchar(256) NULL,
    [EmailConfirmed] bit NOT NULL,
    [PasswordHash] nvarchar(max) NULL,
    [SecurityStamp] nvarchar(max) NULL,
    [ConcurrencyStamp] nvarchar(max) NULL,
    [PhoneNumber] nvarchar(max) NULL,
    [PhoneNumberConfirmed] bit NOT NULL,
    [TwoFactorEnabled] bit NOT NULL,
    [LockoutEnd] datetimeoffset NULL,
    [LockoutEnabled] bit NOT NULL,
    [AccessFailedCount] int NOT NULL,
    CONSTRAINT [PK_AspNetUsers] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_AspNetUsers_AspNetUsers_MedicoId] FOREIGN KEY ([MedicoId]) REFERENCES [AspNetUsers] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_AspNetUsers_Zonas_ZonaId] FOREIGN KEY ([ZonaId]) REFERENCES [Zonas] ([Id])
);

CREATE TABLE [AspNetUserClaims] (
    [Id] int NOT NULL IDENTITY,
    [UserId] nvarchar(450) NOT NULL,
    [ClaimType] nvarchar(max) NULL,
    [ClaimValue] nvarchar(max) NULL,
    CONSTRAINT [PK_AspNetUserClaims] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_AspNetUserClaims_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [AspNetUsers] ([Id]) ON DELETE CASCADE
);

CREATE TABLE [AspNetUserLogins] (
    [LoginProvider] nvarchar(450) NOT NULL,
    [ProviderKey] nvarchar(450) NOT NULL,
    [ProviderDisplayName] nvarchar(max) NULL,
    [UserId] nvarchar(450) NOT NULL,
    CONSTRAINT [PK_AspNetUserLogins] PRIMARY KEY ([LoginProvider], [ProviderKey]),
    CONSTRAINT [FK_AspNetUserLogins_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [AspNetUsers] ([Id]) ON DELETE CASCADE
);

CREATE TABLE [AspNetUserRoles] (
    [UserId] nvarchar(450) NOT NULL,
    [RoleId] nvarchar(450) NOT NULL,
    CONSTRAINT [PK_AspNetUserRoles] PRIMARY KEY ([UserId], [RoleId]),
    CONSTRAINT [FK_AspNetUserRoles_AspNetRoles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [AspNetRoles] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_AspNetUserRoles_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [AspNetUsers] ([Id]) ON DELETE CASCADE
);

CREATE TABLE [AspNetUserTokens] (
    [UserId] nvarchar(450) NOT NULL,
    [LoginProvider] nvarchar(450) NOT NULL,
    [Name] nvarchar(450) NOT NULL,
    [Value] nvarchar(max) NULL,
    CONSTRAINT [PK_AspNetUserTokens] PRIMARY KEY ([UserId], [LoginProvider], [Name]),
    CONSTRAINT [FK_AspNetUserTokens_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [AspNetUsers] ([Id]) ON DELETE CASCADE
);

CREATE INDEX [IX_AspNetRoleClaims_RoleId] ON [AspNetRoleClaims] ([RoleId]);

CREATE UNIQUE INDEX [RoleNameIndex] ON [AspNetRoles] ([NormalizedName]) WHERE [NormalizedName] IS NOT NULL;

CREATE INDEX [IX_AspNetUserClaims_UserId] ON [AspNetUserClaims] ([UserId]);

CREATE INDEX [IX_AspNetUserLogins_UserId] ON [AspNetUserLogins] ([UserId]);

CREATE INDEX [IX_AspNetUserRoles_RoleId] ON [AspNetUserRoles] ([RoleId]);

CREATE INDEX [EmailIndex] ON [AspNetUsers] ([NormalizedEmail]);

CREATE INDEX [IX_AspNetUsers_MedicoId] ON [AspNetUsers] ([MedicoId]);

CREATE INDEX [IX_AspNetUsers_ZonaId] ON [AspNetUsers] ([ZonaId]);

CREATE UNIQUE INDEX [UserNameIndex] ON [AspNetUsers] ([NormalizedUserName]) WHERE [NormalizedUserName] IS NOT NULL;

CREATE INDEX [IX_Razas_EspecieId] ON [Razas] ([EspecieId]);

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20261121161129_Inicial', N'9.0.23');

ALTER TABLE [AspNetUsers] DROP CONSTRAINT [FK_AspNetUsers_Zonas_ZonaId];

ALTER TABLE [Razas] DROP CONSTRAINT [FK_Razas_Especies_EspecieId];

DROP INDEX [IX_Razas_EspecieId] ON [Razas];

DECLARE @var sysname;
SELECT @var = [d].[name]
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[Zonas]') AND [c].[name] = N'Nombre');
IF @var IS NOT NULL EXEC(N'ALTER TABLE [Zonas] DROP CONSTRAINT [' + @var + '];');
ALTER TABLE [Zonas] ALTER COLUMN [Nombre] nvarchar(100) NOT NULL;

DECLARE @var1 sysname;
SELECT @var1 = [d].[name]
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[Servicios]') AND [c].[name] = N'Nombre');
IF @var1 IS NOT NULL EXEC(N'ALTER TABLE [Servicios] DROP CONSTRAINT [' + @var1 + '];');
ALTER TABLE [Servicios] ALTER COLUMN [Nombre] nvarchar(100) NOT NULL;

DECLARE @var2 sysname;
SELECT @var2 = [d].[name]
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[Razas]') AND [c].[name] = N'Nombre');
IF @var2 IS NOT NULL EXEC(N'ALTER TABLE [Razas] DROP CONSTRAINT [' + @var2 + '];');
ALTER TABLE [Razas] ALTER COLUMN [Nombre] nvarchar(100) NOT NULL;

DECLARE @var3 sysname;
SELECT @var3 = [d].[name]
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[Especies]') AND [c].[name] = N'Nombre');
IF @var3 IS NOT NULL EXEC(N'ALTER TABLE [Especies] DROP CONSTRAINT [' + @var3 + '];');
ALTER TABLE [Especies] ALTER COLUMN [Nombre] nvarchar(100) NOT NULL;

DECLARE @var4 sysname;
SELECT @var4 = [d].[name]
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[AspNetUsers]') AND [c].[name] = N'NombreCompleto');
IF @var4 IS NOT NULL EXEC(N'ALTER TABLE [AspNetUsers] DROP CONSTRAINT [' + @var4 + '];');
ALTER TABLE [AspNetUsers] ALTER COLUMN [NombreCompleto] nvarchar(150) NOT NULL;

CREATE TABLE [Dueños] (
    [Id] int NOT NULL IDENTITY,
    [Nombre] nvarchar(150) NOT NULL,
    [Telefono] nvarchar(20) NULL,
    [Direccion] nvarchar(250) NULL,
    CONSTRAINT [PK_Dueños] PRIMARY KEY ([Id])
);

CREATE TABLE [Pacientes] (
    [Id] int NOT NULL IDENTITY,
    [Nombre] nvarchar(100) NOT NULL,
    [FechaNacimiento] datetime2 NULL,
    [RazaId] int NOT NULL,
    [DuenoId] int NOT NULL,
    [TecnicoId] nvarchar(450) NULL,
    CONSTRAINT [PK_Pacientes] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Pacientes_AspNetUsers_TecnicoId] FOREIGN KEY ([TecnicoId]) REFERENCES [AspNetUsers] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Pacientes_Dueños_DuenoId] FOREIGN KEY ([DuenoId]) REFERENCES [Dueños] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Pacientes_Razas_RazaId] FOREIGN KEY ([RazaId]) REFERENCES [Razas] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [Visitas] (
    [Id] int NOT NULL IDENTITY,
    [PacienteId] int NOT NULL,
    [ServicioId] int NOT NULL,
    [TecnicoId] nvarchar(450) NOT NULL,
    [FechaProgramada] datetime2 NOT NULL,
    [Estado] int NOT NULL,
    [FechaRegistro] datetime2 NULL,
    [PesoKg] decimal(6,2) NULL,
    [AlturaCm] decimal(6,2) NULL,
    [Temperatura] decimal(4,1) NULL,
    [Condicion] nvarchar(500) NULL,
    [Latitud] float NULL,
    [Longitud] float NULL,
    [FotoUrl] nvarchar(300) NULL,
    CONSTRAINT [PK_Visitas] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Visitas_AspNetUsers_TecnicoId] FOREIGN KEY ([TecnicoId]) REFERENCES [AspNetUsers] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Visitas_Pacientes_PacienteId] FOREIGN KEY ([PacienteId]) REFERENCES [Pacientes] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Visitas_Servicios_ServicioId] FOREIGN KEY ([ServicioId]) REFERENCES [Servicios] ([Id]) ON DELETE NO ACTION
);

CREATE UNIQUE INDEX [IX_Zonas_Nombre] ON [Zonas] ([Nombre]);

CREATE UNIQUE INDEX [IX_Servicios_Nombre] ON [Servicios] ([Nombre]);

CREATE UNIQUE INDEX [IX_Razas_EspecieId_Nombre] ON [Razas] ([EspecieId], [Nombre]);

CREATE UNIQUE INDEX [IX_Especies_Nombre] ON [Especies] ([Nombre]);

CREATE INDEX [IX_Pacientes_DuenoId] ON [Pacientes] ([DuenoId]);

CREATE INDEX [IX_Pacientes_RazaId] ON [Pacientes] ([RazaId]);

CREATE INDEX [IX_Pacientes_TecnicoId] ON [Pacientes] ([TecnicoId]);

CREATE INDEX [IX_Visitas_PacienteId] ON [Visitas] ([PacienteId]);

CREATE INDEX [IX_Visitas_ServicioId] ON [Visitas] ([ServicioId]);

CREATE INDEX [IX_Visitas_TecnicoId_FechaProgramada] ON [Visitas] ([TecnicoId], [FechaProgramada]);

ALTER TABLE [AspNetUsers] ADD CONSTRAINT [FK_AspNetUsers_Zonas_ZonaId] FOREIGN KEY ([ZonaId]) REFERENCES [Zonas] ([Id]) ON DELETE SET NULL;

ALTER TABLE [Razas] ADD CONSTRAINT [FK_Razas_Especies_EspecieId] FOREIGN KEY ([EspecieId]) REFERENCES [Especies] ([Id]) ON DELETE NO ACTION;

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20261121182642_DuenosPacientesVisitas', N'9.0.23');

COMMIT;
GO

