
create table atletas (
    id_atleta serial primary key,
    apelido varchar(50) not null unique,
    email varchar(100) not null unique,
    senha varchar(100) not null,
    situacao varchar(15) not null default 'ativo',
    constraint chk_situacao
    check (situacao in ('ativo', 'inativo', 'banido'))
);

create table categorias (
    id_categoria serial primary key,
    nome_categoria varchar(60) not null unique,
    descricao varchar(150)
);

create table confrontos (
    id_confronto serial primary key,
    titulo varchar(100) not null,
    id_atleta int not null,
    id_categoria int not null,
    data_agendada timestamp not null,
    situacao_partida varchar(20) not null default 'agendada',
    data_criacao timestamp,
    constraint fk_atleta
    foreign key (id_atleta) references atletas(id_atleta),
    constraint fk_categoria
    foreign key (id_categoria) references categorias(id_categoria),
    constraint chk_partida
    check (situacao_partida in
    ('agendada', 'em andamento', 'finalizada', 'cancelada'))
);

create table registro_confrontos (
    id_registro serial primary key,
    id_confronto int not null,
    descricao varchar(200) not null,
    data_registro timestamp not null default current_timestamp,
    constraint fk_confronto
    foreign key (id_confronto) references confrontos(id_confronto)
);

insert into atletas (apelido, email, senha, situacao)
values
('f4te', 'f4te@email.com', '123456', 'ativo'),
('bsin', 'beon@email.com', '654321', 'ativo'),
('akashi', 'akashi@email.com', 'abc123', 'ativo');

insert into categorias (nome_categoria, descricao)
values
('fps', 'jogos de tiro em primeira pessoa'),
('moba', 'jogos de estrategia em equipe'),
('battle royale', 'jogos de sobrevivencia');

create or replace function fn_validar_confronto()
returns trigger
language plpgsql
as $$
begin
    if not exists (
        select 1
        from atletas
        where id_atleta = new.id_atleta
        and situacao = 'ativo'
    ) then
        raise exception 'o jogador nao esta ativo';
    end if;

    new.data_criacao := current_timestamp;

    return new;
end;
$$;

create trigger trg_validar_partida
before insert on confrontos
for each row
execute function fn_validar_confronto();

create or replace function fn_gerar_historico()
returns trigger
language plpgsql
as $$
begin
    insert into registro_confrontos
    (id_confronto, descricao)
    values
    (
        new.id_confronto,
        'novo confronto cadastrado: ' || new.titulo
    );

    return new;
end;
$$;

create trigger trg_registrar_historico
after insert on confrontos
for each row
execute function fn_gerar_historico();

insert into confrontos
(titulo, id_atleta, id_categoria, data_agendada, situacao_partida)
values
('campeonato mundial', 1, 1, '2026-12-10 14:00:00', 'agendada'),
('torneio dos campeoes', 2, 2, '2026-12-15 16:00:00', 'agendada'),
('desafio supremo', 3, 3, '2026-12-20 18:00:00', 'agendada');

create or replace function fn_buscar_jogadores(termo text)
returns table (
    codigo int,
    nickname varchar,
    email_jogador varchar,
    status_jogador varchar
)
language plpgsql
as $$
begin
    return query
    select
        a.id_atleta,
        a.apelido,
        a.email,
        a.situacao
    from atletas a
    where a.apelido ilike '%' || termo || '%'
       or a.email ilike '%' || termo || '%';
end;
$$;

create or replace view vw_painel_principal as
select
    a.apelido as nickname,
    c.titulo as titulo_partida,
    g.nome_categoria as modalidade,
    c.data_agendada as data_partida,
    c.situacao_partida as status
from confrontos c
inner join atletas a
    on c.id_atleta = a.id_atleta
inner join categorias g
    on c.id_categoria = g.id_categoria;

create or replace view vw_cronograma_partidas as
select
    c.id_confronto,
    c.titulo,
    a.apelido as jogador_responsavel,
    c.data_agendada,
    c.situacao_partida as status,
    (c.data_agendada::date - current_date)
    as dias_restantes
from confrontos c
inner join atletas a
    on c.id_atleta = a.id_atleta
order by c.data_agendada asc;

select * from atletas;
select * from categorias;
select * from confrontos;
select * from registro_confrontos;
select * from fn_buscar_jogadores('f4te');
select * from vw_painel_principal;
select * from vw_cronograma_partidas;
