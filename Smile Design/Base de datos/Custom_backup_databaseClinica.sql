PGDMP         /            	    y         	   dbclinica    12.5    12.5    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    156674 	   dbclinica    DATABASE     �   CREATE DATABASE dbclinica WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'Spanish_Spain.1252' LC_CTYPE = 'Spanish_Spain.1252';
    DROP DATABASE dbclinica;
                postgres    false                       1255    158618    calculo_cuenta(integer)    FUNCTION     	  CREATE FUNCTION public.calculo_cuenta(integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$
begin
if (Select pagoTotal = 0.00 From Pagos Where idpago=$1)
	then
  if (select Exists (Select costoprocedimiento from Pagos pg inner join consultas cl on pg.idconsulta = cl.idconsulta inner join consultaprocedimiento pc on pc.idconsulta = cl.idconsulta inner join procedimientos pr on pr.idprocedimiento = pc.idprocedimiento Where pg.idpago = $1) = false )
  then
	Update Pagos set 
	pagoTotal=(
	Select costoconsulta
	From pagos pg
	Inner join consultas cl on cl.idconsulta = pg.idconsulta
	Where idpago = $1
	),
	pagoDebe=(
	Select costoconsulta
	From pagos pg
	Inner join consultas cl on cl.idconsulta = pg.idconsulta
	Where idpago = $1
	), 
	idestadopago=1 
	where idPago=$1;
else	
	    Update Pagos set 
		pagoTotal=(
		select Sum(costoprocedimiento)
		from Pagos pg
		inner join consultas cl on pg.idconsulta = cl.idconsulta
		inner join consultaprocedimiento pc on pc.idconsulta = cl.idconsulta
		inner join procedimientos pr on pr.idprocedimiento = pc.idprocedimiento
		Where pg.idpago=$1
		),
		pagoDebe=(
		select Sum(costoprocedimiento)
		from Pagos pg
		inner join consultas cl on pg.idconsulta = cl.idconsulta
		inner join consultaprocedimiento pc on pc.idconsulta = cl.idconsulta
		inner join procedimientos pr on pr.idprocedimiento = pc.idprocedimiento
		Where pg.idpago=$1
		), 
		idestadopago=1 
		where idPago=$1;	
	end if;
	else 
	Raise exception 'Error No puede Reescribir sobre una cuenta ya calculada';
end if;
Return;
END;
$_$;
 .   DROP FUNCTION public.calculo_cuenta(integer);
       public          postgres    false                       1255    158619    calculo_saldo(integer, numeric)    FUNCTION     �  CREATE FUNCTION public.calculo_saldo(id_p integer, abono numeric) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
if (Select pagodebe != 0.00 From pagos Where idpago=id_p)
 then
Update Pagos set pagoAbono=abono, pagodebe=(pagodebe-abono), pagosaldo=(pagodebe-abono) where idPago=id_p;
	if (Select abono < pagoDebe from Pagos  where idPago=id_p)
		then
		Raise Notice 'Aún no se completa la cuenta';
	    Return;
	end if;
	if (Select pagoDebe<=0 from Pagos where idPago=id_p)
		then 
		Update Pagos set pagoDebe=0, pagosaldo = 0 where idPago=id_p;
		Update Pagos set idEstadoPago=2 where idPago=id_p;
		Raise Notice 'Pago completo la cuenta';
	end if;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Error al Tratar de Modificar el valor ((%)) ((%)) ',id_p,abono;
        RAISE NOTICE 'Error al Tratar de Modificar el valor ((%)) ((%)) ',id_p, abono;
        RETURN;
    END IF;
  else 
    Raise Exception 'No permitido';
End if;
Return;
END;
$$;
 A   DROP FUNCTION public.calculo_saldo(id_p integer, abono numeric);
       public          postgres    false                       1255    158628    cantidad_consultas()    FUNCTION     U  CREATE FUNCTION public.cantidad_consultas() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	  declare
	  consultas int = (select Max(idconsulta) from consultas);
	  Begin 	  
	  Update cantidadconsultas set idconsulta=(consultas) 
	  Where idcantidadconsulta=(Select max(idcantidadconsulta) from cantidadconsultas);
	  Return null;
end;
$$;
 +   DROP FUNCTION public.cantidad_consultas();
       public          postgres    false                       1255    158624    generar_codigos(integer)    FUNCTION     �  CREATE FUNCTION public.generar_codigos(idtr integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare 
codigo varchar;
begin
codigo = (Select Upper (substring(nombrepaciente,1,5) ||''|| substring(apellidopaciente,1,3) ||''|| substring(md5(random()::text),1,9) )  as Codigo
From Tratamientos tr
Inner join pacienteasignado  ap on ap.idpacienteasignado = tr.idpacienteasignado 
Inner join Pacientes pr on pr.idpaciente = ap.idpaciente
WHERE idtratamiento=idTR);
-----------------------------------
UPDATE tratamientos SET codigotratamiento = codigo Where idtratamiento=idTR;
-----------------------------------
Raise notice 'Codigo: ((%))', codigo;
return;
end;
$$;
 4   DROP FUNCTION public.generar_codigos(idtr integer);
       public          postgres    false            	           1255    158670    generar_codigos_automaticos()    FUNCTION     �  CREATE FUNCTION public.generar_codigos_automaticos() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare 
codigo varchar;
idTr int;
begin
idTr= (Select max(idtratamiento) from tratamientos);
codigo = (Select Upper (substring(nombrepaciente,1,5) ||''|| substring(apellidopaciente,1,3) ||''|| substring(md5(random()::text),1,9) )  as Codigo		  
From Tratamientos tr
Inner join pacienteasignado  ap on ap.idpacienteasignado = tr.idpacienteasignado 
Inner join Pacientes pr on pr.idpaciente = ap.idpaciente
WHERE idtratamiento=idTr);
-----------///------------------------
UPDATE tratamientos SET codigotratamiento = codigo Where idtratamiento=idTr;
----------///------------------------
Raise notice 'Codigo: ((%))', codigo;
return null;
end;
$$;
 4   DROP FUNCTION public.generar_codigos_automaticos();
       public          postgres    false                       1255    166959    historial_pagos()    FUNCTION     B  CREATE FUNCTION public.historial_pagos() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	  Begin 	  
	  Insert into historialPagos (fecharegistro,pagodebeH,pagoabonoH,pagototalH,pagosaldoH,tratamiento,tipopago)
	  Values (current_timestamp,old.pagodebe,old.pagoabono,old.pagototal,old.pagosaldo,old.idconsulta,old.idtipopago);
	  Insert into historialPagos (fecharegistro,pagodebeH,pagoabonoH,pagototalH,pagosaldoH,tratamiento,tipopago)
	  Values (current_timestamp,new.pagodebe,new.pagoabono,new.pagototal,new.pagosaldo,new.idconsulta,new.idtipopago);
	  Return null;
end;
$$;
 (   DROP FUNCTION public.historial_pagos();
       public          postgres    false                       1255    166961    historial_pagos_nombres()    FUNCTION     �  CREATE FUNCTION public.historial_pagos_nombres() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
idH int = (Select Tratamiento From historialPagos Where idhistorial=(Select max(idhistorial) From HistorialPagos));
nombre text =(Select nombrePaciente ||' '|| apellidoPaciente From Pagos pg Inner join consultas cl on cl.idconsulta = pg.idconsulta Inner join cantidadconsultas cc on cc.idconsulta = cl.idconsulta Inner join tratamientos tr on tr.idtratamiento = cc.idtratamiento Inner join pacienteasignado pa on pa.idpacienteasignado = tr.idpacienteasignado Inner join pacientes pt on pt.idpaciente = pa.idpaciente Where idpago=idH);
codigo text =(Select codigotratamiento From Pagos pg  Inner join consultas cl on cl.idconsulta = pg.idconsulta Inner join cantidadconsultas cc on cc.idconsulta = cl.idconsulta Inner join tratamientos tr on tr.idtratamiento = cc.idtratamiento Inner join pacienteasignado pa on pa.idpacienteasignado = tr.idpacienteasignado Inner join pacientes pt on pt.idpaciente = pa.idpaciente Where idpago=idH);
	  Begin 
      Update historialPagos set nombrePaciente =nombre, codigotratamientoh=codigo Where Tratamiento=idH ;
	  Return null;
end;
$$;
 0   DROP FUNCTION public.historial_pagos_nombres();
       public          postgres    false                       1255    158664    insertar_expedientes()    FUNCTION       CREATE FUNCTION public.insertar_expedientes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	  Declare
	  paciente int;
	  Begin
	  paciente = (Select max(idpaciente) from pacientes);
	  Insert into Expedientes (idpaciente) values (paciente);
	  Return null;
end;
$$;
 -   DROP FUNCTION public.insertar_expedientes();
       public          postgres    false            
           1255    158625    insertar_pagos()    FUNCTION     9  CREATE FUNCTION public.insertar_pagos() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	  Begin 	  
	  Insert into pagos (pagodebe, pagoabono, pagototal, pagosaldo, idconsulta, idtipopago, idestadopago)
	  values ('0.00','0.00','0.00','0.00',(select max(idconsulta) from consultas),1,1);
	  Return null;
end;
$$;
 '   DROP FUNCTION public.insertar_pagos();
       public          postgres    false                       1255    158627    insertar_tratamiento(integer)    FUNCTION     �   CREATE FUNCTION public.insertar_tratamiento(id_proced integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
Insert into cantidadconsultas (idtratamiento) values (id_proced);
end;
$$;
 >   DROP FUNCTION public.insertar_tratamiento(id_proced integer);
       public          postgres    false                       1255    158630 <   verificar_fecha_hora_consultas(date, time without time zone)    FUNCTION     �  CREATE FUNCTION public.verificar_fecha_hora_consultas(fecha date, consulta time without time zone) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
if (Select fechaconsulta=(fecha) From Consultas Where fechaconsulta=(fecha)) And ( Select horaconsulta=(consulta) From Consultas Where horaconsulta=(consulta))
then
Raise exception 'Fecha y Hora no pueden ser iguales, debe elegir, por lo menos otra hora del mismo día ((%)), ((%))', fecha, consulta;
elsif (Select fechaconsulta!=(fecha)  From Consultas Where fechaconsulta!=(fecha) Limit 1) And ( Select horaconsulta!=(consulta) From Consultas Where horaconsulta!=(consulta) Limit 1)
then 
Raise exception 'Puede proceder';
end if;
return;
end;
$$;
 b   DROP FUNCTION public.verificar_fecha_hora_consultas(fecha date, consulta time without time zone);
       public          postgres    false                       1255    158631 /   verificar_pacientes_asignados(integer, integer)    FUNCTION     _  CREATE FUNCTION public.verificar_pacientes_asignados(idpa integer, idd integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
if(Select iddoctor=(idD) From pacienteasignado Where iddoctor=(idD) Limit 1) 
		AND (Select idpaciente=(idPa) From pacienteasignado Where idpaciente=(idPa) Limit 1)
then
Raise Exception 'No puede asignar un paciente que ya posee un registro';
elsif (Select iddoctor!=(idD) From pacienteasignado Where iddoctor!=(idD) Limit 1) 
		AND (Select idpaciente!=(idPa) From pacienteasignado Where idpaciente!=(idPa) Limit 1)
then
Raise Notice 'Puede proceder';
end if;
return;
end;
$$;
 O   DROP FUNCTION public.verificar_pacientes_asignados(idpa integer, idd integer);
       public          postgres    false            �            1259    158593    archivos    TABLE     �   CREATE TABLE public.archivos (
    idarchivo integer NOT NULL,
    notas character varying(10485760) NOT NULL,
    observacionesperiodontograma character varying(10485760) NOT NULL,
    idexpediente integer NOT NULL
);
    DROP TABLE public.archivos;
       public         heap    postgres    false            �            1259    158591    archivos_idarchivo_seq    SEQUENCE     �   CREATE SEQUENCE public.archivos_idarchivo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.archivos_idarchivo_seq;
       public          postgres    false    251            �           0    0    archivos_idarchivo_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.archivos_idarchivo_seq OWNED BY public.archivos.idarchivo;
          public          postgres    false    250            �            1259    158536    cantidadconsultas    TABLE     �   CREATE TABLE public.cantidadconsultas (
    idcantidadconsulta integer NOT NULL,
    idconsulta integer,
    idtratamiento integer NOT NULL
);
 %   DROP TABLE public.cantidadconsultas;
       public         heap    postgres    false            �            1259    158534 (   cantidadconsultas_idcantidadconsulta_seq    SEQUENCE     �   CREATE SEQUENCE public.cantidadconsultas_idcantidadconsulta_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ?   DROP SEQUENCE public.cantidadconsultas_idcantidadconsulta_seq;
       public          postgres    false    245            �           0    0 (   cantidadconsultas_idcantidadconsulta_seq    SEQUENCE OWNED BY     u   ALTER SEQUENCE public.cantidadconsultas_idcantidadconsulta_seq OWNED BY public.cantidadconsultas.idcantidadconsulta;
          public          postgres    false    244            �            1259    158497    causaconsulta    TABLE     v   CREATE TABLE public.causaconsulta (
    idcausaconsulta integer NOT NULL,
    causa character varying(30) NOT NULL
);
 !   DROP TABLE public.causaconsulta;
       public         heap    postgres    false            �            1259    158495 !   causaconsulta_idcausaconsulta_seq    SEQUENCE     �   CREATE SEQUENCE public.causaconsulta_idcausaconsulta_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 8   DROP SEQUENCE public.causaconsulta_idcausaconsulta_seq;
       public          postgres    false    239            �           0    0 !   causaconsulta_idcausaconsulta_seq    SEQUENCE OWNED BY     g   ALTER SEQUENCE public.causaconsulta_idcausaconsulta_seq OWNED BY public.causaconsulta.idcausaconsulta;
          public          postgres    false    238                       1259    166997    codigosesiones    TABLE     �   CREATE TABLE public.codigosesiones (
    idcodigosesion integer NOT NULL,
    codigo character varying(56),
    idusuario integer
);
 "   DROP TABLE public.codigosesiones;
       public         heap    postgres    false                       1259    166995 !   codigosesiones_idcodigosesion_seq    SEQUENCE     �   CREATE SEQUENCE public.codigosesiones_idcodigosesion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 8   DROP SEQUENCE public.codigosesiones_idcodigosesion_seq;
       public          postgres    false    261            �           0    0 !   codigosesiones_idcodigosesion_seq    SEQUENCE OWNED BY     g   ALTER SEQUENCE public.codigosesiones_idcodigosesion_seq OWNED BY public.codigosesiones.idcodigosesion;
          public          postgres    false    260            �            1259    158518    consultaprocedimiento    TABLE     �   CREATE TABLE public.consultaprocedimiento (
    idconsultaprocedimiento integer NOT NULL,
    idconsulta integer NOT NULL,
    idprocedimiento integer NOT NULL
);
 )   DROP TABLE public.consultaprocedimiento;
       public         heap    postgres    false            �            1259    158516 1   consultaprocedimiento_idconsultaprocedimiento_seq    SEQUENCE     �   CREATE SEQUENCE public.consultaprocedimiento_idconsultaprocedimiento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 H   DROP SEQUENCE public.consultaprocedimiento_idconsultaprocedimiento_seq;
       public          postgres    false    243            �           0    0 1   consultaprocedimiento_idconsultaprocedimiento_seq    SEQUENCE OWNED BY     �   ALTER SEQUENCE public.consultaprocedimiento_idconsultaprocedimiento_seq OWNED BY public.consultaprocedimiento.idconsultaprocedimiento;
          public          postgres    false    242            �            1259    158505 	   consultas    TABLE       CREATE TABLE public.consultas (
    idconsulta integer NOT NULL,
    notasconsulta character varying(155) NOT NULL,
    costoconsulta numeric(4,2) NOT NULL,
    fechaconsulta date,
    horaconsulta time without time zone,
    idcausaconsulta integer NOT NULL
);
    DROP TABLE public.consultas;
       public         heap    postgres    false            �            1259    158503    consultas_idconsulta_seq    SEQUENCE     �   CREATE SEQUENCE public.consultas_idconsulta_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.consultas_idconsulta_seq;
       public          postgres    false    241            �           0    0    consultas_idconsulta_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.consultas_idconsulta_seq OWNED BY public.consultas.idconsulta;
          public          postgres    false    240                       1259    175198    conteointentosfallidos    TABLE     �   CREATE TABLE public.conteointentosfallidos (
    idconteo integer NOT NULL,
    intentosfallidos integer,
    usuario character varying(15),
    fecharegistro date
);
 *   DROP TABLE public.conteointentosfallidos;
       public         heap    postgres    false                       1259    175196 #   conteointentosfallidos_idconteo_seq    SEQUENCE     �   CREATE SEQUENCE public.conteointentosfallidos_idconteo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 :   DROP SEQUENCE public.conteointentosfallidos_idconteo_seq;
       public          postgres    false    263            �           0    0 #   conteointentosfallidos_idconteo_seq    SEQUENCE OWNED BY     k   ALTER SEQUENCE public.conteointentosfallidos_idconteo_seq OWNED BY public.conteointentosfallidos.idconteo;
          public          postgres    false    262            �            1259    158388    doctores    TABLE     �  CREATE TABLE public.doctores (
    iddoctor integer NOT NULL,
    nombredoctor character varying(25) NOT NULL,
    apellidodoctor character varying(25) NOT NULL,
    direcciondoctor character varying(155) NOT NULL,
    telefonodoctor character varying(9) NOT NULL,
    correodoctor character varying(55) NOT NULL,
    fotodoctor character varying(100),
    aliasdoctor character varying(15) NOT NULL,
    clavedoctor character varying(100) NOT NULL,
    idestadodoctor integer NOT NULL
);
    DROP TABLE public.doctores;
       public         heap    postgres    false            �            1259    158386    doctores_iddoctor_seq    SEQUENCE     �   CREATE SEQUENCE public.doctores_iddoctor_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.doctores_iddoctor_seq;
       public          postgres    false    223            �           0    0    doctores_iddoctor_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.doctores_iddoctor_seq OWNED BY public.doctores.iddoctor;
          public          postgres    false    222            �            1259    158380    especialidad    TABLE     {   CREATE TABLE public.especialidad (
    idespecialidad integer NOT NULL,
    especialidad character varying(25) NOT NULL
);
     DROP TABLE public.especialidad;
       public         heap    postgres    false            �            1259    158378    especialidad_idespecialidad_seq    SEQUENCE     �   CREATE SEQUENCE public.especialidad_idespecialidad_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 6   DROP SEQUENCE public.especialidad_idespecialidad_seq;
       public          postgres    false    221            �           0    0    especialidad_idespecialidad_seq    SEQUENCE OWNED BY     c   ALTER SEQUENCE public.especialidad_idespecialidad_seq OWNED BY public.especialidad.idespecialidad;
          public          postgres    false    220            �            1259    158401    especialidaddoctor    TABLE     �   CREATE TABLE public.especialidaddoctor (
    idespecialidaddoctor integer NOT NULL,
    iddoctor integer NOT NULL,
    idespecialidad integer NOT NULL
);
 &   DROP TABLE public.especialidaddoctor;
       public         heap    postgres    false            �            1259    158399 +   especialidaddoctor_idespecialidaddoctor_seq    SEQUENCE     �   CREATE SEQUENCE public.especialidaddoctor_idespecialidaddoctor_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 B   DROP SEQUENCE public.especialidaddoctor_idespecialidaddoctor_seq;
       public          postgres    false    225            �           0    0 +   especialidaddoctor_idespecialidaddoctor_seq    SEQUENCE OWNED BY     {   ALTER SEQUENCE public.especialidaddoctor_idespecialidaddoctor_seq OWNED BY public.especialidaddoctor.idespecialidaddoctor;
          public          postgres    false    224            �            1259    158372    estadodoctor    TABLE     {   CREATE TABLE public.estadodoctor (
    idestadodoctor integer NOT NULL,
    estadodoctor character varying(15) NOT NULL
);
     DROP TABLE public.estadodoctor;
       public         heap    postgres    false            �            1259    158370    estadodoctor_idestadodoctor_seq    SEQUENCE     �   CREATE SEQUENCE public.estadodoctor_idestadodoctor_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 6   DROP SEQUENCE public.estadodoctor_idestadodoctor_seq;
       public          postgres    false    219            �           0    0    estadodoctor_idestadodoctor_seq    SEQUENCE OWNED BY     c   ALTER SEQUENCE public.estadodoctor_idestadodoctor_seq OWNED BY public.estadodoctor.idestadodoctor;
          public          postgres    false    218            �            1259    158266    estadopaciente    TABLE     �   CREATE TABLE public.estadopaciente (
    idestadopaciente integer NOT NULL,
    estadopaciente character varying(15) NOT NULL
);
 "   DROP TABLE public.estadopaciente;
       public         heap    postgres    false            �            1259    158264 #   estadopaciente_idestadopaciente_seq    SEQUENCE     �   CREATE SEQUENCE public.estadopaciente_idestadopaciente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 :   DROP SEQUENCE public.estadopaciente_idestadopaciente_seq;
       public          postgres    false    209            �           0    0 #   estadopaciente_idestadopaciente_seq    SEQUENCE OWNED BY     k   ALTER SEQUENCE public.estadopaciente_idestadopaciente_seq OWNED BY public.estadopaciente.idestadopaciente;
          public          postgres    false    208            �            1259    158562 
   estadopago    TABLE     u   CREATE TABLE public.estadopago (
    idestadopago integer NOT NULL,
    estadopago character varying(15) NOT NULL
);
    DROP TABLE public.estadopago;
       public         heap    postgres    false            �            1259    158560    estadopago_idestadopago_seq    SEQUENCE     �   CREATE SEQUENCE public.estadopago_idestadopago_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 2   DROP SEQUENCE public.estadopago_idestadopago_seq;
       public          postgres    false    249            �           0    0    estadopago_idestadopago_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE public.estadopago_idestadopago_seq OWNED BY public.estadopago.idestadopago;
          public          postgres    false    248            �            1259    158458    estadotratamiento    TABLE     �   CREATE TABLE public.estadotratamiento (
    idestadotratamiento integer NOT NULL,
    estadotratamiento character varying(15) NOT NULL
);
 %   DROP TABLE public.estadotratamiento;
       public         heap    postgres    false            �            1259    158456 )   estadotratamiento_idestadotratamiento_seq    SEQUENCE     �   CREATE SEQUENCE public.estadotratamiento_idestadotratamiento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 @   DROP SEQUENCE public.estadotratamiento_idestadotratamiento_seq;
       public          postgres    false    233            �           0    0 )   estadotratamiento_idestadotratamiento_seq    SEQUENCE OWNED BY     w   ALTER SEQUENCE public.estadotratamiento_idestadotratamiento_seq OWNED BY public.estadotratamiento.idestadotratamiento;
          public          postgres    false    232            �            1259    158232    estadousuario    TABLE     ~   CREATE TABLE public.estadousuario (
    idestadousuario integer NOT NULL,
    estadousuario character varying(15) NOT NULL
);
 !   DROP TABLE public.estadousuario;
       public         heap    postgres    false            �            1259    158230 !   estadousuario_idestadousuario_seq    SEQUENCE     �   CREATE SEQUENCE public.estadousuario_idestadousuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 8   DROP SEQUENCE public.estadousuario_idestadousuario_seq;
       public          postgres    false    203            �           0    0 !   estadousuario_idestadousuario_seq    SEQUENCE OWNED BY     g   ALTER SEQUENCE public.estadousuario_idestadousuario_seq OWNED BY public.estadousuario.idestadousuario;
          public          postgres    false    202            �            1259    158359    expedientes    TABLE     �   CREATE TABLE public.expedientes (
    idexpediente integer NOT NULL,
    odontograma character varying(100),
    periodontograma character varying(100),
    idpaciente integer NOT NULL
);
    DROP TABLE public.expedientes;
       public         heap    postgres    false            �            1259    158357    expedientes_idexpediente_seq    SEQUENCE     �   CREATE SEQUENCE public.expedientes_idexpediente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE public.expedientes_idexpediente_seq;
       public          postgres    false    217            �           0    0    expedientes_idexpediente_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE public.expedientes_idexpediente_seq OWNED BY public.expedientes.idexpediente;
          public          postgres    false    216            �            1259    166950    historialpagos    TABLE     a  CREATE TABLE public.historialpagos (
    idhistorial integer NOT NULL,
    nombrepaciente text,
    fecharegistro timestamp without time zone,
    pagodebeh numeric(5,2),
    pagoabonoh numeric(5,2),
    pagototalh numeric(5,2),
    pagosaldoh numeric(5,2),
    tratamiento integer,
    tipopago integer,
    codigotratamientoh character varying(57)
);
 "   DROP TABLE public.historialpagos;
       public         heap    postgres    false            �            1259    166948    historialpagos_idhistorial_seq    SEQUENCE     �   CREATE SEQUENCE public.historialpagos_idhistorial_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE public.historialpagos_idhistorial_seq;
       public          postgres    false    255            �           0    0    historialpagos_idhistorial_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE public.historialpagos_idhistorial_seq OWNED BY public.historialpagos.idhistorial;
          public          postgres    false    254                       1259    166972    historialsesiones    TABLE     `  CREATE TABLE public.historialsesiones (
    idhistorial integer NOT NULL,
    ip character varying(45),
    usuario character varying(15),
    nombrecompleto character varying(45),
    region character varying(55),
    zonahoraria character varying(55),
    distribuidor character varying(55),
    pais character varying(55),
    fecharegistro date
);
 %   DROP TABLE public.historialsesiones;
       public         heap    postgres    false                        1259    166970 !   historialsesiones_idhistorial_seq    SEQUENCE     �   CREATE SEQUENCE public.historialsesiones_idhistorial_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 8   DROP SEQUENCE public.historialsesiones_idhistorial_seq;
       public          postgres    false    257            �           0    0 !   historialsesiones_idhistorial_seq    SEQUENCE OWNED BY     g   ALTER SEQUENCE public.historialsesiones_idhistorial_seq OWNED BY public.historialsesiones.idhistorial;
          public          postgres    false    256            �            1259    158419    pacienteasignado    TABLE     �   CREATE TABLE public.pacienteasignado (
    idpacienteasignado integer NOT NULL,
    idpaciente integer NOT NULL,
    iddoctor integer NOT NULL
);
 $   DROP TABLE public.pacienteasignado;
       public         heap    postgres    false            �            1259    158417 '   pacienteasignado_idpacienteasignado_seq    SEQUENCE     �   CREATE SEQUENCE public.pacienteasignado_idpacienteasignado_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 >   DROP SEQUENCE public.pacienteasignado_idpacienteasignado_seq;
       public          postgres    false    227            �           0    0 '   pacienteasignado_idpacienteasignado_seq    SEQUENCE OWNED BY     s   ALTER SEQUENCE public.pacienteasignado_idpacienteasignado_seq OWNED BY public.pacienteasignado.idpacienteasignado;
          public          postgres    false    226            �            1259    158274 	   pacientes    TABLE       CREATE TABLE public.pacientes (
    idpaciente integer NOT NULL,
    nombrepaciente character varying(25) NOT NULL,
    apellidopaciente character varying(25) NOT NULL,
    fechanacimiento date NOT NULL,
    duipaciente character varying(10) NOT NULL,
    direccionpaciente character varying(155) NOT NULL,
    telefonopaciente character varying(9) NOT NULL,
    correopaciente character varying(55) NOT NULL,
    fotopaciente character varying(100),
    idestadopaciente integer NOT NULL,
    clavepaciente character varying(100)
);
    DROP TABLE public.pacientes;
       public         heap    postgres    false            �            1259    158272    pacientes_idpaciente_seq    SEQUENCE     �   CREATE SEQUENCE public.pacientes_idpaciente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.pacientes_idpaciente_seq;
       public          postgres    false    211            �           0    0    pacientes_idpaciente_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.pacientes_idpaciente_seq OWNED BY public.pacientes.idpaciente;
          public          postgres    false    210            �            1259    166923    pagos    TABLE     3  CREATE TABLE public.pagos (
    idpago integer NOT NULL,
    pagodebe numeric(5,2) NOT NULL,
    pagoabono numeric(5,2) NOT NULL,
    pagototal numeric(5,2) NOT NULL,
    pagosaldo numeric(5,2) NOT NULL,
    idconsulta integer NOT NULL,
    idtipopago integer NOT NULL,
    idestadopago integer NOT NULL
);
    DROP TABLE public.pagos;
       public         heap    postgres    false            �            1259    166921    pagos_idpago_seq    SEQUENCE     �   CREATE SEQUENCE public.pagos_idpago_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.pagos_idpago_seq;
       public          postgres    false    253            �           0    0    pagos_idpago_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE public.pagos_idpago_seq OWNED BY public.pagos.idpago;
          public          postgres    false    252            �            1259    158287 	   preguntas    TABLE     p   CREATE TABLE public.preguntas (
    idpregunta integer NOT NULL,
    pregunta character varying(69) NOT NULL
);
    DROP TABLE public.preguntas;
       public         heap    postgres    false            �            1259    158285    preguntas_idpregunta_seq    SEQUENCE     �   CREATE SEQUENCE public.preguntas_idpregunta_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.preguntas_idpregunta_seq;
       public          postgres    false    213            �           0    0    preguntas_idpregunta_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.preguntas_idpregunta_seq OWNED BY public.preguntas.idpregunta;
          public          postgres    false    212            �            1259    158489    procedimientos    TABLE     �   CREATE TABLE public.procedimientos (
    idprocedimiento integer NOT NULL,
    nombreprocedimiento character varying(30) NOT NULL,
    descripcionprocedimiento character varying(155) NOT NULL,
    costoprocedimiento numeric(4,2) NOT NULL
);
 "   DROP TABLE public.procedimientos;
       public         heap    postgres    false            �            1259    158487 "   procedimientos_idprocedimiento_seq    SEQUENCE     �   CREATE SEQUENCE public.procedimientos_idprocedimiento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 9   DROP SEQUENCE public.procedimientos_idprocedimiento_seq;
       public          postgres    false    237            �           0    0 "   procedimientos_idprocedimiento_seq    SEQUENCE OWNED BY     i   ALTER SEQUENCE public.procedimientos_idprocedimiento_seq OWNED BY public.procedimientos.idprocedimiento;
          public          postgres    false    236            �            1259    158437    recetas    TABLE     �   CREATE TABLE public.recetas (
    idreceta integer NOT NULL,
    farmaco character varying(40) NOT NULL,
    fecharegistro date NOT NULL,
    idpacienteasignado integer NOT NULL
);
    DROP TABLE public.recetas;
       public         heap    postgres    false            �            1259    158435    recetas_idreceta_seq    SEQUENCE     �   CREATE SEQUENCE public.recetas_idreceta_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.recetas_idreceta_seq;
       public          postgres    false    229            �           0    0    recetas_idreceta_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.recetas_idreceta_seq OWNED BY public.recetas.idreceta;
          public          postgres    false    228            �            1259    158295 
   respuestas    TABLE     {  CREATE TABLE public.respuestas (
    idrespuesta integer NOT NULL,
    respuesta1 character varying(2),
    idpregunta1 integer,
    respuesta2 character varying(2),
    idpregunta2 integer,
    respuesta3 character varying(2),
    idpregunta3 integer,
    respuesta4 character varying(2),
    idpregunta4 integer,
    respuesta5 character varying(2),
    idpregunta5 integer,
    respuesta6 character varying(2),
    idpregunta6 integer,
    respuesta7 character varying(2),
    idpregunta7 integer,
    respuesta8 character varying(2),
    idpregunta8 integer,
    pacientemedicamento character varying(1000000) NOT NULL,
    idpaciente integer NOT NULL,
    CONSTRAINT respuestas_respuesta1_check CHECK ((((respuesta1)::text = 'Si'::text) OR ((respuesta1)::text = 'No'::text))),
    CONSTRAINT respuestas_respuesta2_check CHECK ((((respuesta2)::text = 'Si'::text) OR ((respuesta2)::text = 'No'::text))),
    CONSTRAINT respuestas_respuesta3_check CHECK ((((respuesta3)::text = 'Si'::text) OR ((respuesta3)::text = 'No'::text))),
    CONSTRAINT respuestas_respuesta4_check CHECK ((((respuesta4)::text = 'Si'::text) OR ((respuesta4)::text = 'No'::text))),
    CONSTRAINT respuestas_respuesta5_check CHECK ((((respuesta5)::text = 'Si'::text) OR ((respuesta5)::text = 'No'::text))),
    CONSTRAINT respuestas_respuesta6_check CHECK ((((respuesta6)::text = 'Si'::text) OR ((respuesta6)::text = 'No'::text))),
    CONSTRAINT respuestas_respuesta7_check CHECK ((((respuesta7)::text = 'Si'::text) OR ((respuesta7)::text = 'No'::text))),
    CONSTRAINT respuestas_respuesta8_check CHECK ((((respuesta8)::text = 'Si'::text) OR ((respuesta8)::text = 'No'::text)))
);
    DROP TABLE public.respuestas;
       public         heap    postgres    false            �            1259    158293    respuestas_idrespuesta_seq    SEQUENCE     �   CREATE SEQUENCE public.respuestas_idrespuesta_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.respuestas_idrespuesta_seq;
       public          postgres    false    215            �           0    0    respuestas_idrespuesta_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.respuestas_idrespuesta_seq OWNED BY public.respuestas.idrespuesta;
          public          postgres    false    214            �            1259    158554    tipopago    TABLE     o   CREATE TABLE public.tipopago (
    idtipopago integer NOT NULL,
    tipopago character varying(15) NOT NULL
);
    DROP TABLE public.tipopago;
       public         heap    postgres    false            �            1259    158552    tipopago_idtipopago_seq    SEQUENCE     �   CREATE SEQUENCE public.tipopago_idtipopago_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.tipopago_idtipopago_seq;
       public          postgres    false    247            �           0    0    tipopago_idtipopago_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.tipopago_idtipopago_seq OWNED BY public.tipopago.idtipopago;
          public          postgres    false    246            �            1259    158450    tipotratamiento    TABLE     �   CREATE TABLE public.tipotratamiento (
    idtipotratamiento integer NOT NULL,
    tipotratamiento character varying(25) NOT NULL
);
 #   DROP TABLE public.tipotratamiento;
       public         heap    postgres    false            �            1259    158448 %   tipotratamiento_idtipotratamiento_seq    SEQUENCE     �   CREATE SEQUENCE public.tipotratamiento_idtipotratamiento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 <   DROP SEQUENCE public.tipotratamiento_idtipotratamiento_seq;
       public          postgres    false    231            �           0    0 %   tipotratamiento_idtipotratamiento_seq    SEQUENCE OWNED BY     o   ALTER SEQUENCE public.tipotratamiento_idtipotratamiento_seq OWNED BY public.tipotratamiento.idtipotratamiento;
          public          postgres    false    230            �            1259    158240    tipousuario    TABLE     x   CREATE TABLE public.tipousuario (
    idtipousuario integer NOT NULL,
    tipousuario character varying(25) NOT NULL
);
    DROP TABLE public.tipousuario;
       public         heap    postgres    false            �            1259    158238    tipousuario_idtipousuario_seq    SEQUENCE     �   CREATE SEQUENCE public.tipousuario_idtipousuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 4   DROP SEQUENCE public.tipousuario_idtipousuario_seq;
       public          postgres    false    205            �           0    0    tipousuario_idtipousuario_seq    SEQUENCE OWNED BY     _   ALTER SEQUENCE public.tipousuario_idtipousuario_seq OWNED BY public.tipousuario.idtipousuario;
          public          postgres    false    204            �            1259    158466    tratamientos    TABLE     L  CREATE TABLE public.tratamientos (
    idtratamiento integer NOT NULL,
    fechainicio date NOT NULL,
    descripciontratamiento character varying(155) NOT NULL,
    idpacienteasignado integer NOT NULL,
    idtipotratamiento integer NOT NULL,
    idestadotratamiento integer NOT NULL,
    codigotratamiento character varying(57)
);
     DROP TABLE public.tratamientos;
       public         heap    postgres    false            �            1259    158464    tratamientos_idtratamiento_seq    SEQUENCE     �   CREATE SEQUENCE public.tratamientos_idtratamiento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE public.tratamientos_idtratamiento_seq;
       public          postgres    false    235            �           0    0    tratamientos_idtratamiento_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE public.tratamientos_idtratamiento_seq OWNED BY public.tratamientos.idtratamiento;
          public          postgres    false    234            �            1259    158248    usuarios    TABLE     �  CREATE TABLE public.usuarios (
    idusuario integer NOT NULL,
    nombreusuario character varying(25) NOT NULL,
    apellidousuario character varying(25) NOT NULL,
    direccionusuario character varying(155) NOT NULL,
    telefonousuario character varying(9) NOT NULL,
    correousuario character varying(55) NOT NULL,
    aliasusuario character varying(15) NOT NULL,
    claveusuario character varying(100) NOT NULL,
    idestadousuario integer NOT NULL,
    idtipousuario integer NOT NULL,
    fechacambioclave date,
    intentosfallidos integer,
    CONSTRAINT usuarios_intentosfallidos_check CHECK (((intentosfallidos = 1) OR (intentosfallidos = 2) OR (intentosfallidos = 3)))
);
    DROP TABLE public.usuarios;
       public         heap    postgres    false            �            1259    158246    usuarios_idusuario_seq    SEQUENCE     �   CREATE SEQUENCE public.usuarios_idusuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.usuarios_idusuario_seq;
       public          postgres    false    207            �           0    0    usuarios_idusuario_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.usuarios_idusuario_seq OWNED BY public.usuarios.idusuario;
          public          postgres    false    206                       1259    166988    verificarcodigos    TABLE     �   CREATE TABLE public.verificarcodigos (
    idcodigos integer NOT NULL,
    codigo character varying(10),
    identificador character varying(56)
);
 $   DROP TABLE public.verificarcodigos;
       public         heap    postgres    false                       1259    166986    verificarcodigos_idcodigos_seq    SEQUENCE     �   CREATE SEQUENCE public.verificarcodigos_idcodigos_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE public.verificarcodigos_idcodigos_seq;
       public          postgres    false    259            �           0    0    verificarcodigos_idcodigos_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE public.verificarcodigos_idcodigos_seq OWNED BY public.verificarcodigos.idcodigos;
          public          postgres    false    258            c           2604    158596    archivos idarchivo    DEFAULT     x   ALTER TABLE ONLY public.archivos ALTER COLUMN idarchivo SET DEFAULT nextval('public.archivos_idarchivo_seq'::regclass);
 A   ALTER TABLE public.archivos ALTER COLUMN idarchivo DROP DEFAULT;
       public          postgres    false    251    250    251            `           2604    158539 $   cantidadconsultas idcantidadconsulta    DEFAULT     �   ALTER TABLE ONLY public.cantidadconsultas ALTER COLUMN idcantidadconsulta SET DEFAULT nextval('public.cantidadconsultas_idcantidadconsulta_seq'::regclass);
 S   ALTER TABLE public.cantidadconsultas ALTER COLUMN idcantidadconsulta DROP DEFAULT;
       public          postgres    false    244    245    245            ]           2604    158500    causaconsulta idcausaconsulta    DEFAULT     �   ALTER TABLE ONLY public.causaconsulta ALTER COLUMN idcausaconsulta SET DEFAULT nextval('public.causaconsulta_idcausaconsulta_seq'::regclass);
 L   ALTER TABLE public.causaconsulta ALTER COLUMN idcausaconsulta DROP DEFAULT;
       public          postgres    false    239    238    239            h           2604    167000    codigosesiones idcodigosesion    DEFAULT     �   ALTER TABLE ONLY public.codigosesiones ALTER COLUMN idcodigosesion SET DEFAULT nextval('public.codigosesiones_idcodigosesion_seq'::regclass);
 L   ALTER TABLE public.codigosesiones ALTER COLUMN idcodigosesion DROP DEFAULT;
       public          postgres    false    261    260    261            _           2604    158521 -   consultaprocedimiento idconsultaprocedimiento    DEFAULT     �   ALTER TABLE ONLY public.consultaprocedimiento ALTER COLUMN idconsultaprocedimiento SET DEFAULT nextval('public.consultaprocedimiento_idconsultaprocedimiento_seq'::regclass);
 \   ALTER TABLE public.consultaprocedimiento ALTER COLUMN idconsultaprocedimiento DROP DEFAULT;
       public          postgres    false    242    243    243            ^           2604    158508    consultas idconsulta    DEFAULT     |   ALTER TABLE ONLY public.consultas ALTER COLUMN idconsulta SET DEFAULT nextval('public.consultas_idconsulta_seq'::regclass);
 C   ALTER TABLE public.consultas ALTER COLUMN idconsulta DROP DEFAULT;
       public          postgres    false    240    241    241            i           2604    175201    conteointentosfallidos idconteo    DEFAULT     �   ALTER TABLE ONLY public.conteointentosfallidos ALTER COLUMN idconteo SET DEFAULT nextval('public.conteointentosfallidos_idconteo_seq'::regclass);
 N   ALTER TABLE public.conteointentosfallidos ALTER COLUMN idconteo DROP DEFAULT;
       public          postgres    false    262    263    263            U           2604    158391    doctores iddoctor    DEFAULT     v   ALTER TABLE ONLY public.doctores ALTER COLUMN iddoctor SET DEFAULT nextval('public.doctores_iddoctor_seq'::regclass);
 @   ALTER TABLE public.doctores ALTER COLUMN iddoctor DROP DEFAULT;
       public          postgres    false    222    223    223            T           2604    158383    especialidad idespecialidad    DEFAULT     �   ALTER TABLE ONLY public.especialidad ALTER COLUMN idespecialidad SET DEFAULT nextval('public.especialidad_idespecialidad_seq'::regclass);
 J   ALTER TABLE public.especialidad ALTER COLUMN idespecialidad DROP DEFAULT;
       public          postgres    false    221    220    221            V           2604    158404 '   especialidaddoctor idespecialidaddoctor    DEFAULT     �   ALTER TABLE ONLY public.especialidaddoctor ALTER COLUMN idespecialidaddoctor SET DEFAULT nextval('public.especialidaddoctor_idespecialidaddoctor_seq'::regclass);
 V   ALTER TABLE public.especialidaddoctor ALTER COLUMN idespecialidaddoctor DROP DEFAULT;
       public          postgres    false    224    225    225            S           2604    158375    estadodoctor idestadodoctor    DEFAULT     �   ALTER TABLE ONLY public.estadodoctor ALTER COLUMN idestadodoctor SET DEFAULT nextval('public.estadodoctor_idestadodoctor_seq'::regclass);
 J   ALTER TABLE public.estadodoctor ALTER COLUMN idestadodoctor DROP DEFAULT;
       public          postgres    false    218    219    219            F           2604    158269    estadopaciente idestadopaciente    DEFAULT     �   ALTER TABLE ONLY public.estadopaciente ALTER COLUMN idestadopaciente SET DEFAULT nextval('public.estadopaciente_idestadopaciente_seq'::regclass);
 N   ALTER TABLE public.estadopaciente ALTER COLUMN idestadopaciente DROP DEFAULT;
       public          postgres    false    208    209    209            b           2604    158565    estadopago idestadopago    DEFAULT     �   ALTER TABLE ONLY public.estadopago ALTER COLUMN idestadopago SET DEFAULT nextval('public.estadopago_idestadopago_seq'::regclass);
 F   ALTER TABLE public.estadopago ALTER COLUMN idestadopago DROP DEFAULT;
       public          postgres    false    248    249    249            Z           2604    158461 %   estadotratamiento idestadotratamiento    DEFAULT     �   ALTER TABLE ONLY public.estadotratamiento ALTER COLUMN idestadotratamiento SET DEFAULT nextval('public.estadotratamiento_idestadotratamiento_seq'::regclass);
 T   ALTER TABLE public.estadotratamiento ALTER COLUMN idestadotratamiento DROP DEFAULT;
       public          postgres    false    233    232    233            B           2604    158235    estadousuario idestadousuario    DEFAULT     �   ALTER TABLE ONLY public.estadousuario ALTER COLUMN idestadousuario SET DEFAULT nextval('public.estadousuario_idestadousuario_seq'::regclass);
 L   ALTER TABLE public.estadousuario ALTER COLUMN idestadousuario DROP DEFAULT;
       public          postgres    false    202    203    203            R           2604    158362    expedientes idexpediente    DEFAULT     �   ALTER TABLE ONLY public.expedientes ALTER COLUMN idexpediente SET DEFAULT nextval('public.expedientes_idexpediente_seq'::regclass);
 G   ALTER TABLE public.expedientes ALTER COLUMN idexpediente DROP DEFAULT;
       public          postgres    false    216    217    217            e           2604    166953    historialpagos idhistorial    DEFAULT     �   ALTER TABLE ONLY public.historialpagos ALTER COLUMN idhistorial SET DEFAULT nextval('public.historialpagos_idhistorial_seq'::regclass);
 I   ALTER TABLE public.historialpagos ALTER COLUMN idhistorial DROP DEFAULT;
       public          postgres    false    254    255    255            f           2604    166975    historialsesiones idhistorial    DEFAULT     �   ALTER TABLE ONLY public.historialsesiones ALTER COLUMN idhistorial SET DEFAULT nextval('public.historialsesiones_idhistorial_seq'::regclass);
 L   ALTER TABLE public.historialsesiones ALTER COLUMN idhistorial DROP DEFAULT;
       public          postgres    false    256    257    257            W           2604    158422 #   pacienteasignado idpacienteasignado    DEFAULT     �   ALTER TABLE ONLY public.pacienteasignado ALTER COLUMN idpacienteasignado SET DEFAULT nextval('public.pacienteasignado_idpacienteasignado_seq'::regclass);
 R   ALTER TABLE public.pacienteasignado ALTER COLUMN idpacienteasignado DROP DEFAULT;
       public          postgres    false    226    227    227            G           2604    158277    pacientes idpaciente    DEFAULT     |   ALTER TABLE ONLY public.pacientes ALTER COLUMN idpaciente SET DEFAULT nextval('public.pacientes_idpaciente_seq'::regclass);
 C   ALTER TABLE public.pacientes ALTER COLUMN idpaciente DROP DEFAULT;
       public          postgres    false    210    211    211            d           2604    166926    pagos idpago    DEFAULT     l   ALTER TABLE ONLY public.pagos ALTER COLUMN idpago SET DEFAULT nextval('public.pagos_idpago_seq'::regclass);
 ;   ALTER TABLE public.pagos ALTER COLUMN idpago DROP DEFAULT;
       public          postgres    false    253    252    253            H           2604    158290    preguntas idpregunta    DEFAULT     |   ALTER TABLE ONLY public.preguntas ALTER COLUMN idpregunta SET DEFAULT nextval('public.preguntas_idpregunta_seq'::regclass);
 C   ALTER TABLE public.preguntas ALTER COLUMN idpregunta DROP DEFAULT;
       public          postgres    false    213    212    213            \           2604    158492    procedimientos idprocedimiento    DEFAULT     �   ALTER TABLE ONLY public.procedimientos ALTER COLUMN idprocedimiento SET DEFAULT nextval('public.procedimientos_idprocedimiento_seq'::regclass);
 M   ALTER TABLE public.procedimientos ALTER COLUMN idprocedimiento DROP DEFAULT;
       public          postgres    false    237    236    237            X           2604    158440    recetas idreceta    DEFAULT     t   ALTER TABLE ONLY public.recetas ALTER COLUMN idreceta SET DEFAULT nextval('public.recetas_idreceta_seq'::regclass);
 ?   ALTER TABLE public.recetas ALTER COLUMN idreceta DROP DEFAULT;
       public          postgres    false    228    229    229            I           2604    158298    respuestas idrespuesta    DEFAULT     �   ALTER TABLE ONLY public.respuestas ALTER COLUMN idrespuesta SET DEFAULT nextval('public.respuestas_idrespuesta_seq'::regclass);
 E   ALTER TABLE public.respuestas ALTER COLUMN idrespuesta DROP DEFAULT;
       public          postgres    false    214    215    215            a           2604    158557    tipopago idtipopago    DEFAULT     z   ALTER TABLE ONLY public.tipopago ALTER COLUMN idtipopago SET DEFAULT nextval('public.tipopago_idtipopago_seq'::regclass);
 B   ALTER TABLE public.tipopago ALTER COLUMN idtipopago DROP DEFAULT;
       public          postgres    false    246    247    247            Y           2604    158453 !   tipotratamiento idtipotratamiento    DEFAULT     �   ALTER TABLE ONLY public.tipotratamiento ALTER COLUMN idtipotratamiento SET DEFAULT nextval('public.tipotratamiento_idtipotratamiento_seq'::regclass);
 P   ALTER TABLE public.tipotratamiento ALTER COLUMN idtipotratamiento DROP DEFAULT;
       public          postgres    false    230    231    231            C           2604    158243    tipousuario idtipousuario    DEFAULT     �   ALTER TABLE ONLY public.tipousuario ALTER COLUMN idtipousuario SET DEFAULT nextval('public.tipousuario_idtipousuario_seq'::regclass);
 H   ALTER TABLE public.tipousuario ALTER COLUMN idtipousuario DROP DEFAULT;
       public          postgres    false    204    205    205            [           2604    158469    tratamientos idtratamiento    DEFAULT     �   ALTER TABLE ONLY public.tratamientos ALTER COLUMN idtratamiento SET DEFAULT nextval('public.tratamientos_idtratamiento_seq'::regclass);
 I   ALTER TABLE public.tratamientos ALTER COLUMN idtratamiento DROP DEFAULT;
       public          postgres    false    234    235    235            D           2604    158251    usuarios idusuario    DEFAULT     x   ALTER TABLE ONLY public.usuarios ALTER COLUMN idusuario SET DEFAULT nextval('public.usuarios_idusuario_seq'::regclass);
 A   ALTER TABLE public.usuarios ALTER COLUMN idusuario DROP DEFAULT;
       public          postgres    false    206    207    207            g           2604    166991    verificarcodigos idcodigos    DEFAULT     �   ALTER TABLE ONLY public.verificarcodigos ALTER COLUMN idcodigos SET DEFAULT nextval('public.verificarcodigos_idcodigos_seq'::regclass);
 I   ALTER TABLE public.verificarcodigos ALTER COLUMN idcodigos DROP DEFAULT;
       public          postgres    false    259    258    259            �          0    158593    archivos 
   TABLE DATA           `   COPY public.archivos (idarchivo, notas, observacionesperiodontograma, idexpediente) FROM stdin;
    public          postgres    false    251   K�      ~          0    158536    cantidadconsultas 
   TABLE DATA           Z   COPY public.cantidadconsultas (idcantidadconsulta, idconsulta, idtratamiento) FROM stdin;
    public          postgres    false    245   T�      x          0    158497    causaconsulta 
   TABLE DATA           ?   COPY public.causaconsulta (idcausaconsulta, causa) FROM stdin;
    public          postgres    false    239   �      �          0    166997    codigosesiones 
   TABLE DATA           K   COPY public.codigosesiones (idcodigosesion, codigo, idusuario) FROM stdin;
    public          postgres    false    261   \�      |          0    158518    consultaprocedimiento 
   TABLE DATA           e   COPY public.consultaprocedimiento (idconsultaprocedimiento, idconsulta, idprocedimiento) FROM stdin;
    public          postgres    false    243   �      z          0    158505 	   consultas 
   TABLE DATA           {   COPY public.consultas (idconsulta, notasconsulta, costoconsulta, fechaconsulta, horaconsulta, idcausaconsulta) FROM stdin;
    public          postgres    false    241   ��      �          0    175198    conteointentosfallidos 
   TABLE DATA           d   COPY public.conteointentosfallidos (idconteo, intentosfallidos, usuario, fecharegistro) FROM stdin;
    public          postgres    false    263   ��      h          0    158388    doctores 
   TABLE DATA           �   COPY public.doctores (iddoctor, nombredoctor, apellidodoctor, direcciondoctor, telefonodoctor, correodoctor, fotodoctor, aliasdoctor, clavedoctor, idestadodoctor) FROM stdin;
    public          postgres    false    223   ,�      f          0    158380    especialidad 
   TABLE DATA           D   COPY public.especialidad (idespecialidad, especialidad) FROM stdin;
    public          postgres    false    221   ��      j          0    158401    especialidaddoctor 
   TABLE DATA           \   COPY public.especialidaddoctor (idespecialidaddoctor, iddoctor, idespecialidad) FROM stdin;
    public          postgres    false    225   B�      d          0    158372    estadodoctor 
   TABLE DATA           D   COPY public.estadodoctor (idestadodoctor, estadodoctor) FROM stdin;
    public          postgres    false    219   ��      Z          0    158266    estadopaciente 
   TABLE DATA           J   COPY public.estadopaciente (idestadopaciente, estadopaciente) FROM stdin;
    public          postgres    false    209   �      �          0    158562 
   estadopago 
   TABLE DATA           >   COPY public.estadopago (idestadopago, estadopago) FROM stdin;
    public          postgres    false    249   .�      r          0    158458    estadotratamiento 
   TABLE DATA           S   COPY public.estadotratamiento (idestadotratamiento, estadotratamiento) FROM stdin;
    public          postgres    false    233   p�      T          0    158232    estadousuario 
   TABLE DATA           G   COPY public.estadousuario (idestadousuario, estadousuario) FROM stdin;
    public          postgres    false    203   ��      b          0    158359    expedientes 
   TABLE DATA           ]   COPY public.expedientes (idexpediente, odontograma, periodontograma, idpaciente) FROM stdin;
    public          postgres    false    217   ��      �          0    166950    historialpagos 
   TABLE DATA           �   COPY public.historialpagos (idhistorial, nombrepaciente, fecharegistro, pagodebeh, pagoabonoh, pagototalh, pagosaldoh, tratamiento, tipopago, codigotratamientoh) FROM stdin;
    public          postgres    false    255   ��      �          0    166972    historialsesiones 
   TABLE DATA           �   COPY public.historialsesiones (idhistorial, ip, usuario, nombrecompleto, region, zonahoraria, distribuidor, pais, fecharegistro) FROM stdin;
    public          postgres    false    257   ��      l          0    158419    pacienteasignado 
   TABLE DATA           T   COPY public.pacienteasignado (idpacienteasignado, idpaciente, iddoctor) FROM stdin;
    public          postgres    false    227   ��      \          0    158274 	   pacientes 
   TABLE DATA           �   COPY public.pacientes (idpaciente, nombrepaciente, apellidopaciente, fechanacimiento, duipaciente, direccionpaciente, telefonopaciente, correopaciente, fotopaciente, idestadopaciente, clavepaciente) FROM stdin;
    public          postgres    false    211   ��      �          0    166923    pagos 
   TABLE DATA           x   COPY public.pagos (idpago, pagodebe, pagoabono, pagototal, pagosaldo, idconsulta, idtipopago, idestadopago) FROM stdin;
    public          postgres    false    253   �      ^          0    158287 	   preguntas 
   TABLE DATA           9   COPY public.preguntas (idpregunta, pregunta) FROM stdin;
    public          postgres    false    213   ��      v          0    158489    procedimientos 
   TABLE DATA           |   COPY public.procedimientos (idprocedimiento, nombreprocedimiento, descripcionprocedimiento, costoprocedimiento) FROM stdin;
    public          postgres    false    237   ��      n          0    158437    recetas 
   TABLE DATA           W   COPY public.recetas (idreceta, farmaco, fecharegistro, idpacienteasignado) FROM stdin;
    public          postgres    false    229   �      `          0    158295 
   respuestas 
   TABLE DATA             COPY public.respuestas (idrespuesta, respuesta1, idpregunta1, respuesta2, idpregunta2, respuesta3, idpregunta3, respuesta4, idpregunta4, respuesta5, idpregunta5, respuesta6, idpregunta6, respuesta7, idpregunta7, respuesta8, idpregunta8, pacientemedicamento, idpaciente) FROM stdin;
    public          postgres    false    215   ��      �          0    158554    tipopago 
   TABLE DATA           8   COPY public.tipopago (idtipopago, tipopago) FROM stdin;
    public          postgres    false    247   ��      p          0    158450    tipotratamiento 
   TABLE DATA           M   COPY public.tipotratamiento (idtipotratamiento, tipotratamiento) FROM stdin;
    public          postgres    false    231   �      V          0    158240    tipousuario 
   TABLE DATA           A   COPY public.tipousuario (idtipousuario, tipousuario) FROM stdin;
    public          postgres    false    205   Z�      t          0    158466    tratamientos 
   TABLE DATA           �   COPY public.tratamientos (idtratamiento, fechainicio, descripciontratamiento, idpacienteasignado, idtipotratamiento, idestadotratamiento, codigotratamiento) FROM stdin;
    public          postgres    false    235   ��      X          0    158248    usuarios 
   TABLE DATA           �   COPY public.usuarios (idusuario, nombreusuario, apellidousuario, direccionusuario, telefonousuario, correousuario, aliasusuario, claveusuario, idestadousuario, idtipousuario, fechacambioclave, intentosfallidos) FROM stdin;
    public          postgres    false    207   �      �          0    166988    verificarcodigos 
   TABLE DATA           L   COPY public.verificarcodigos (idcodigos, codigo, identificador) FROM stdin;
    public          postgres    false    259   �      �           0    0    archivos_idarchivo_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.archivos_idarchivo_seq', 108, true);
          public          postgres    false    250            �           0    0 (   cantidadconsultas_idcantidadconsulta_seq    SEQUENCE SET     X   SELECT pg_catalog.setval('public.cantidadconsultas_idcantidadconsulta_seq', 323, true);
          public          postgres    false    244            �           0    0 !   causaconsulta_idcausaconsulta_seq    SEQUENCE SET     O   SELECT pg_catalog.setval('public.causaconsulta_idcausaconsulta_seq', 8, true);
          public          postgres    false    238            �           0    0 !   codigosesiones_idcodigosesion_seq    SEQUENCE SET     P   SELECT pg_catalog.setval('public.codigosesiones_idcodigosesion_seq', 59, true);
          public          postgres    false    260            �           0    0 1   consultaprocedimiento_idconsultaprocedimiento_seq    SEQUENCE SET     a   SELECT pg_catalog.setval('public.consultaprocedimiento_idconsultaprocedimiento_seq', 310, true);
          public          postgres    false    242            �           0    0    consultas_idconsulta_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.consultas_idconsulta_seq', 133, true);
          public          postgres    false    240            �           0    0 #   conteointentosfallidos_idconteo_seq    SEQUENCE SET     R   SELECT pg_catalog.setval('public.conteointentosfallidos_idconteo_seq', 17, true);
          public          postgres    false    262            �           0    0    doctores_iddoctor_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.doctores_iddoctor_seq', 103, true);
          public          postgres    false    222            �           0    0    especialidad_idespecialidad_seq    SEQUENCE SET     N   SELECT pg_catalog.setval('public.especialidad_idespecialidad_seq', 12, true);
          public          postgres    false    220            �           0    0 +   especialidaddoctor_idespecialidaddoctor_seq    SEQUENCE SET     Z   SELECT pg_catalog.setval('public.especialidaddoctor_idespecialidaddoctor_seq', 1, false);
          public          postgres    false    224            �           0    0    estadodoctor_idestadodoctor_seq    SEQUENCE SET     N   SELECT pg_catalog.setval('public.estadodoctor_idestadodoctor_seq', 1, false);
          public          postgres    false    218            �           0    0 #   estadopaciente_idestadopaciente_seq    SEQUENCE SET     R   SELECT pg_catalog.setval('public.estadopaciente_idestadopaciente_seq', 1, false);
          public          postgres    false    208            �           0    0    estadopago_idestadopago_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.estadopago_idestadopago_seq', 1, false);
          public          postgres    false    248            �           0    0 )   estadotratamiento_idestadotratamiento_seq    SEQUENCE SET     X   SELECT pg_catalog.setval('public.estadotratamiento_idestadotratamiento_seq', 1, false);
          public          postgres    false    232            �           0    0 !   estadousuario_idestadousuario_seq    SEQUENCE SET     O   SELECT pg_catalog.setval('public.estadousuario_idestadousuario_seq', 2, true);
          public          postgres    false    202            �           0    0    expedientes_idexpediente_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.expedientes_idexpediente_seq', 109, true);
          public          postgres    false    216            �           0    0    historialpagos_idhistorial_seq    SEQUENCE SET     M   SELECT pg_catalog.setval('public.historialpagos_idhistorial_seq', 66, true);
          public          postgres    false    254            �           0    0 !   historialsesiones_idhistorial_seq    SEQUENCE SET     P   SELECT pg_catalog.setval('public.historialsesiones_idhistorial_seq', 70, true);
          public          postgres    false    256            �           0    0 '   pacienteasignado_idpacienteasignado_seq    SEQUENCE SET     W   SELECT pg_catalog.setval('public.pacienteasignado_idpacienteasignado_seq', 106, true);
          public          postgres    false    226            �           0    0    pacientes_idpaciente_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.pacientes_idpaciente_seq', 107, true);
          public          postgres    false    210            �           0    0    pagos_idpago_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.pagos_idpago_seq', 121, true);
          public          postgres    false    252            �           0    0    preguntas_idpregunta_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.preguntas_idpregunta_seq', 1, false);
          public          postgres    false    212            �           0    0 "   procedimientos_idprocedimiento_seq    SEQUENCE SET     Q   SELECT pg_catalog.setval('public.procedimientos_idprocedimiento_seq', 10, true);
          public          postgres    false    236            �           0    0    recetas_idreceta_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.recetas_idreceta_seq', 1, false);
          public          postgres    false    228            �           0    0    respuestas_idrespuesta_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.respuestas_idrespuesta_seq', 8, true);
          public          postgres    false    214            �           0    0    tipopago_idtipopago_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.tipopago_idtipopago_seq', 1, false);
          public          postgres    false    246            �           0    0 %   tipotratamiento_idtipotratamiento_seq    SEQUENCE SET     T   SELECT pg_catalog.setval('public.tipotratamiento_idtipotratamiento_seq', 1, false);
          public          postgres    false    230            �           0    0    tipousuario_idtipousuario_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('public.tipousuario_idtipousuario_seq', 3, true);
          public          postgres    false    204            �           0    0    tratamientos_idtratamiento_seq    SEQUENCE SET     N   SELECT pg_catalog.setval('public.tratamientos_idtratamiento_seq', 107, true);
          public          postgres    false    234            �           0    0    usuarios_idusuario_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.usuarios_idusuario_seq', 109, true);
          public          postgres    false    206            �           0    0    verificarcodigos_idcodigos_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.verificarcodigos_idcodigos_seq', 9, true);
          public          postgres    false    258            �           2606    158601    archivos archivos_pkey 
   CONSTRAINT     [   ALTER TABLE ONLY public.archivos
    ADD CONSTRAINT archivos_pkey PRIMARY KEY (idarchivo);
 @   ALTER TABLE ONLY public.archivos DROP CONSTRAINT archivos_pkey;
       public            postgres    false    251            �           2606    158541 (   cantidadconsultas cantidadconsultas_pkey 
   CONSTRAINT     v   ALTER TABLE ONLY public.cantidadconsultas
    ADD CONSTRAINT cantidadconsultas_pkey PRIMARY KEY (idcantidadconsulta);
 R   ALTER TABLE ONLY public.cantidadconsultas DROP CONSTRAINT cantidadconsultas_pkey;
       public            postgres    false    245            �           2606    158502     causaconsulta causaconsulta_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY public.causaconsulta
    ADD CONSTRAINT causaconsulta_pkey PRIMARY KEY (idcausaconsulta);
 J   ALTER TABLE ONLY public.causaconsulta DROP CONSTRAINT causaconsulta_pkey;
       public            postgres    false    239            �           2606    167002 "   codigosesiones codigosesiones_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.codigosesiones
    ADD CONSTRAINT codigosesiones_pkey PRIMARY KEY (idcodigosesion);
 L   ALTER TABLE ONLY public.codigosesiones DROP CONSTRAINT codigosesiones_pkey;
       public            postgres    false    261            �           2606    158523 0   consultaprocedimiento consultaprocedimiento_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.consultaprocedimiento
    ADD CONSTRAINT consultaprocedimiento_pkey PRIMARY KEY (idconsultaprocedimiento);
 Z   ALTER TABLE ONLY public.consultaprocedimiento DROP CONSTRAINT consultaprocedimiento_pkey;
       public            postgres    false    243            �           2606    158510    consultas consultas_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.consultas
    ADD CONSTRAINT consultas_pkey PRIMARY KEY (idconsulta);
 B   ALTER TABLE ONLY public.consultas DROP CONSTRAINT consultas_pkey;
       public            postgres    false    241            �           2606    175203 2   conteointentosfallidos conteointentosfallidos_pkey 
   CONSTRAINT     v   ALTER TABLE ONLY public.conteointentosfallidos
    ADD CONSTRAINT conteointentosfallidos_pkey PRIMARY KEY (idconteo);
 \   ALTER TABLE ONLY public.conteointentosfallidos DROP CONSTRAINT conteointentosfallidos_pkey;
       public            postgres    false    263            �           2606    158393    doctores doctores_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.doctores
    ADD CONSTRAINT doctores_pkey PRIMARY KEY (iddoctor);
 @   ALTER TABLE ONLY public.doctores DROP CONSTRAINT doctores_pkey;
       public            postgres    false    223                       2606    158385    especialidad especialidad_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.especialidad
    ADD CONSTRAINT especialidad_pkey PRIMARY KEY (idespecialidad);
 H   ALTER TABLE ONLY public.especialidad DROP CONSTRAINT especialidad_pkey;
       public            postgres    false    221            �           2606    158406 *   especialidaddoctor especialidaddoctor_pkey 
   CONSTRAINT     z   ALTER TABLE ONLY public.especialidaddoctor
    ADD CONSTRAINT especialidaddoctor_pkey PRIMARY KEY (idespecialidaddoctor);
 T   ALTER TABLE ONLY public.especialidaddoctor DROP CONSTRAINT especialidaddoctor_pkey;
       public            postgres    false    225            }           2606    158377    estadodoctor estadodoctor_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.estadodoctor
    ADD CONSTRAINT estadodoctor_pkey PRIMARY KEY (idestadodoctor);
 H   ALTER TABLE ONLY public.estadodoctor DROP CONSTRAINT estadodoctor_pkey;
       public            postgres    false    219            q           2606    158271 "   estadopaciente estadopaciente_pkey 
   CONSTRAINT     n   ALTER TABLE ONLY public.estadopaciente
    ADD CONSTRAINT estadopaciente_pkey PRIMARY KEY (idestadopaciente);
 L   ALTER TABLE ONLY public.estadopaciente DROP CONSTRAINT estadopaciente_pkey;
       public            postgres    false    209            �           2606    158567    estadopago estadopago_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.estadopago
    ADD CONSTRAINT estadopago_pkey PRIMARY KEY (idestadopago);
 D   ALTER TABLE ONLY public.estadopago DROP CONSTRAINT estadopago_pkey;
       public            postgres    false    249            �           2606    158463 (   estadotratamiento estadotratamiento_pkey 
   CONSTRAINT     w   ALTER TABLE ONLY public.estadotratamiento
    ADD CONSTRAINT estadotratamiento_pkey PRIMARY KEY (idestadotratamiento);
 R   ALTER TABLE ONLY public.estadotratamiento DROP CONSTRAINT estadotratamiento_pkey;
       public            postgres    false    233            k           2606    158237     estadousuario estadousuario_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY public.estadousuario
    ADD CONSTRAINT estadousuario_pkey PRIMARY KEY (idestadousuario);
 J   ALTER TABLE ONLY public.estadousuario DROP CONSTRAINT estadousuario_pkey;
       public            postgres    false    203            {           2606    158364    expedientes expedientes_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.expedientes
    ADD CONSTRAINT expedientes_pkey PRIMARY KEY (idexpediente);
 F   ALTER TABLE ONLY public.expedientes DROP CONSTRAINT expedientes_pkey;
       public            postgres    false    217            �           2606    166958 "   historialpagos historialpagos_pkey 
   CONSTRAINT     i   ALTER TABLE ONLY public.historialpagos
    ADD CONSTRAINT historialpagos_pkey PRIMARY KEY (idhistorial);
 L   ALTER TABLE ONLY public.historialpagos DROP CONSTRAINT historialpagos_pkey;
       public            postgres    false    255            �           2606    166977 (   historialsesiones historialsesiones_pkey 
   CONSTRAINT     o   ALTER TABLE ONLY public.historialsesiones
    ADD CONSTRAINT historialsesiones_pkey PRIMARY KEY (idhistorial);
 R   ALTER TABLE ONLY public.historialsesiones DROP CONSTRAINT historialsesiones_pkey;
       public            postgres    false    257            �           2606    158424 &   pacienteasignado pacienteasignado_pkey 
   CONSTRAINT     t   ALTER TABLE ONLY public.pacienteasignado
    ADD CONSTRAINT pacienteasignado_pkey PRIMARY KEY (idpacienteasignado);
 P   ALTER TABLE ONLY public.pacienteasignado DROP CONSTRAINT pacienteasignado_pkey;
       public            postgres    false    227            u           2606    158279    pacientes pacientes_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.pacientes
    ADD CONSTRAINT pacientes_pkey PRIMARY KEY (idpaciente);
 B   ALTER TABLE ONLY public.pacientes DROP CONSTRAINT pacientes_pkey;
       public            postgres    false    211            �           2606    166928    pagos pagos_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_pkey PRIMARY KEY (idpago);
 :   ALTER TABLE ONLY public.pagos DROP CONSTRAINT pagos_pkey;
       public            postgres    false    253            w           2606    158292    preguntas preguntas_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.preguntas
    ADD CONSTRAINT preguntas_pkey PRIMARY KEY (idpregunta);
 B   ALTER TABLE ONLY public.preguntas DROP CONSTRAINT preguntas_pkey;
       public            postgres    false    213            �           2606    158494 "   procedimientos procedimientos_pkey 
   CONSTRAINT     m   ALTER TABLE ONLY public.procedimientos
    ADD CONSTRAINT procedimientos_pkey PRIMARY KEY (idprocedimiento);
 L   ALTER TABLE ONLY public.procedimientos DROP CONSTRAINT procedimientos_pkey;
       public            postgres    false    237            �           2606    158442    recetas recetas_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.recetas
    ADD CONSTRAINT recetas_pkey PRIMARY KEY (idreceta);
 >   ALTER TABLE ONLY public.recetas DROP CONSTRAINT recetas_pkey;
       public            postgres    false    229            y           2606    158311    respuestas respuestas_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY public.respuestas
    ADD CONSTRAINT respuestas_pkey PRIMARY KEY (idrespuesta);
 D   ALTER TABLE ONLY public.respuestas DROP CONSTRAINT respuestas_pkey;
       public            postgres    false    215            �           2606    158559    tipopago tipopago_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.tipopago
    ADD CONSTRAINT tipopago_pkey PRIMARY KEY (idtipopago);
 @   ALTER TABLE ONLY public.tipopago DROP CONSTRAINT tipopago_pkey;
       public            postgres    false    247            �           2606    158455 $   tipotratamiento tipotratamiento_pkey 
   CONSTRAINT     q   ALTER TABLE ONLY public.tipotratamiento
    ADD CONSTRAINT tipotratamiento_pkey PRIMARY KEY (idtipotratamiento);
 N   ALTER TABLE ONLY public.tipotratamiento DROP CONSTRAINT tipotratamiento_pkey;
       public            postgres    false    231            m           2606    158245    tipousuario tipousuario_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY public.tipousuario
    ADD CONSTRAINT tipousuario_pkey PRIMARY KEY (idtipousuario);
 F   ALTER TABLE ONLY public.tipousuario DROP CONSTRAINT tipousuario_pkey;
       public            postgres    false    205            �           2606    158471    tratamientos tratamientos_pkey 
   CONSTRAINT     g   ALTER TABLE ONLY public.tratamientos
    ADD CONSTRAINT tratamientos_pkey PRIMARY KEY (idtratamiento);
 H   ALTER TABLE ONLY public.tratamientos DROP CONSTRAINT tratamientos_pkey;
       public            postgres    false    235            o           2606    158253    usuarios usuarios_pkey 
   CONSTRAINT     [   ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (idusuario);
 @   ALTER TABLE ONLY public.usuarios DROP CONSTRAINT usuarios_pkey;
       public            postgres    false    207            �           2606    166993 &   verificarcodigos verificarcodigos_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY public.verificarcodigos
    ADD CONSTRAINT verificarcodigos_pkey PRIMARY KEY (idcodigos);
 P   ALTER TABLE ONLY public.verificarcodigos DROP CONSTRAINT verificarcodigos_pkey;
       public            postgres    false    259            �           1259    158676    causas_consultas    INDEX     R   CREATE UNIQUE INDEX causas_consultas ON public.causaconsulta USING btree (causa);
 $   DROP INDEX public.causas_consultas;
       public            postgres    false    239            r           1259    158673    dui_paciente    INDEX     P   CREATE UNIQUE INDEX dui_paciente ON public.pacientes USING btree (duipaciente);
     DROP INDEX public.dui_paciente;
       public            postgres    false    211            �           1259    158675    especialidades    INDEX     V   CREATE UNIQUE INDEX especialidades ON public.especialidad USING btree (especialidad);
 "   DROP INDEX public.especialidades;
       public            postgres    false    221            �           1259    158678    indiceconsultas    INDEX     N   CREATE INDEX indiceconsultas ON public.consultas USING btree (notasconsulta);
 #   DROP INDEX public.indiceconsultas;
       public            postgres    false    241            s           1259    158677    indicepacientes    INDEX     a   CREATE INDEX indicepacientes ON public.pacientes USING btree (nombrepaciente, apellidopaciente);
 #   DROP INDEX public.indicepacientes;
       public            postgres    false    211    211            �           1259    158682    indicesdoctores    INDEX     }   CREATE INDEX indicesdoctores ON public.doctores USING btree (nombredoctor, apellidodoctor, direcciondoctor, telefonodoctor);
 #   DROP INDEX public.indicesdoctores;
       public            postgres    false    223    223    223    223            �           1259    158681    indicetratamientos    INDEX     j   CREATE INDEX indicetratamientos ON public.tratamientos USING btree (fechainicio, descripciontratamiento);
 &   DROP INDEX public.indicetratamientos;
       public            postgres    false    235    235            �           2620    158671 -   tratamientos codigos_automaticos_tratamientos    TRIGGER     �   CREATE TRIGGER codigos_automaticos_tratamientos AFTER INSERT ON public.tratamientos FOR EACH ROW EXECUTE FUNCTION public.generar_codigos_automaticos();
 F   DROP TRIGGER codigos_automaticos_tratamientos ON public.tratamientos;
       public          postgres    false    235    265            �           2620    158665 $   pacientes hoja_expedientes_pacientes    TRIGGER     �   CREATE TRIGGER hoja_expedientes_pacientes AFTER INSERT ON public.pacientes FOR EACH ROW EXECUTE FUNCTION public.insertar_expedientes();
 =   DROP TRIGGER hoja_expedientes_pacientes ON public.pacientes;
       public          postgres    false    211    264            �           2620    166944    consultas hoja_pagos_pacientes    TRIGGER     |   CREATE TRIGGER hoja_pagos_pacientes AFTER INSERT ON public.consultas FOR EACH ROW EXECUTE FUNCTION public.insertar_pagos();
 7   DROP TRIGGER hoja_pagos_pacientes ON public.consultas;
       public          postgres    false    266    241            �           2620    158626 !   tratamientos hoja_pagos_pacientes    TRIGGER        CREATE TRIGGER hoja_pagos_pacientes AFTER INSERT ON public.tratamientos FOR EACH ROW EXECUTE FUNCTION public.insertar_pagos();
 :   DROP TRIGGER hoja_pagos_pacientes ON public.tratamientos;
       public          postgres    false    266    235            �           2620    166960    pagos hoja_pagos_tratamientos    TRIGGER     |   CREATE TRIGGER hoja_pagos_tratamientos AFTER UPDATE ON public.pagos FOR EACH ROW EXECUTE FUNCTION public.historial_pagos();
 6   DROP TRIGGER hoja_pagos_tratamientos ON public.pagos;
       public          postgres    false    267    253            �           2620    166962 %   pagos hoja_pagos_tratamientos_nombres    TRIGGER     �   CREATE TRIGGER hoja_pagos_tratamientos_nombres AFTER UPDATE ON public.pagos FOR EACH ROW EXECUTE FUNCTION public.historial_pagos_nombres();
 >   DROP TRIGGER hoja_pagos_tratamientos_nombres ON public.pagos;
       public          postgres    false    285    253            �           2620    158629    consultas insert_consulta    TRIGGER     {   CREATE TRIGGER insert_consulta AFTER INSERT ON public.consultas FOR EACH ROW EXECUTE FUNCTION public.cantidad_consultas();
 2   DROP TRIGGER insert_consulta ON public.consultas;
       public          postgres    false    241    269            �           2606    158602 #   archivos archivos_idexpediente_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.archivos
    ADD CONSTRAINT archivos_idexpediente_fkey FOREIGN KEY (idexpediente) REFERENCES public.expedientes(idexpediente);
 M   ALTER TABLE ONLY public.archivos DROP CONSTRAINT archivos_idexpediente_fkey;
       public          postgres    false    251    2939    217            �           2606    158542 3   cantidadconsultas cantidadconsultas_idconsulta_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.cantidadconsultas
    ADD CONSTRAINT cantidadconsultas_idconsulta_fkey FOREIGN KEY (idconsulta) REFERENCES public.consultas(idconsulta);
 ]   ALTER TABLE ONLY public.cantidadconsultas DROP CONSTRAINT cantidadconsultas_idconsulta_fkey;
       public          postgres    false    2967    241    245            �           2606    158644 6   cantidadconsultas cantidadconsultas_idtratamiento_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.cantidadconsultas
    ADD CONSTRAINT cantidadconsultas_idtratamiento_fkey FOREIGN KEY (idtratamiento) REFERENCES public.tratamientos(idtratamiento) ON DELETE CASCADE;
 `   ALTER TABLE ONLY public.cantidadconsultas DROP CONSTRAINT cantidadconsultas_idtratamiento_fkey;
       public          postgres    false    235    2960    245            �           2606    158524 ;   consultaprocedimiento consultaprocedimiento_idconsulta_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.consultaprocedimiento
    ADD CONSTRAINT consultaprocedimiento_idconsulta_fkey FOREIGN KEY (idconsulta) REFERENCES public.consultas(idconsulta);
 e   ALTER TABLE ONLY public.consultaprocedimiento DROP CONSTRAINT consultaprocedimiento_idconsulta_fkey;
       public          postgres    false    2967    243    241            �           2606    158529 @   consultaprocedimiento consultaprocedimiento_idprocedimiento_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.consultaprocedimiento
    ADD CONSTRAINT consultaprocedimiento_idprocedimiento_fkey FOREIGN KEY (idprocedimiento) REFERENCES public.procedimientos(idprocedimiento);
 j   ALTER TABLE ONLY public.consultaprocedimiento DROP CONSTRAINT consultaprocedimiento_idprocedimiento_fkey;
       public          postgres    false    243    237    2962            �           2606    158511 (   consultas consultas_idcausaconsulta_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.consultas
    ADD CONSTRAINT consultas_idcausaconsulta_fkey FOREIGN KEY (idcausaconsulta) REFERENCES public.causaconsulta(idcausaconsulta);
 R   ALTER TABLE ONLY public.consultas DROP CONSTRAINT consultas_idcausaconsulta_fkey;
       public          postgres    false    2964    239    241            �           2606    158394 %   doctores doctores_idestadodoctor_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.doctores
    ADD CONSTRAINT doctores_idestadodoctor_fkey FOREIGN KEY (idestadodoctor) REFERENCES public.estadodoctor(idestadodoctor);
 O   ALTER TABLE ONLY public.doctores DROP CONSTRAINT doctores_idestadodoctor_fkey;
       public          postgres    false    223    2941    219            �           2606    158407 3   especialidaddoctor especialidaddoctor_iddoctor_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.especialidaddoctor
    ADD CONSTRAINT especialidaddoctor_iddoctor_fkey FOREIGN KEY (iddoctor) REFERENCES public.doctores(iddoctor);
 ]   ALTER TABLE ONLY public.especialidaddoctor DROP CONSTRAINT especialidaddoctor_iddoctor_fkey;
       public          postgres    false    223    2946    225            �           2606    158412 9   especialidaddoctor especialidaddoctor_idespecialidad_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.especialidaddoctor
    ADD CONSTRAINT especialidaddoctor_idespecialidad_fkey FOREIGN KEY (idespecialidad) REFERENCES public.especialidad(idespecialidad);
 c   ALTER TABLE ONLY public.especialidaddoctor DROP CONSTRAINT especialidaddoctor_idespecialidad_fkey;
       public          postgres    false    221    2943    225            �           2606    158365 '   expedientes expedientes_idpaciente_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.expedientes
    ADD CONSTRAINT expedientes_idpaciente_fkey FOREIGN KEY (idpaciente) REFERENCES public.pacientes(idpaciente);
 Q   ALTER TABLE ONLY public.expedientes DROP CONSTRAINT expedientes_idpaciente_fkey;
       public          postgres    false    211    217    2933            �           2606    158430 /   pacienteasignado pacienteasignado_iddoctor_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.pacienteasignado
    ADD CONSTRAINT pacienteasignado_iddoctor_fkey FOREIGN KEY (iddoctor) REFERENCES public.doctores(iddoctor);
 Y   ALTER TABLE ONLY public.pacienteasignado DROP CONSTRAINT pacienteasignado_iddoctor_fkey;
       public          postgres    false    2946    227    223            �           2606    158425 1   pacienteasignado pacienteasignado_idpaciente_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.pacienteasignado
    ADD CONSTRAINT pacienteasignado_idpaciente_fkey FOREIGN KEY (idpaciente) REFERENCES public.pacientes(idpaciente);
 [   ALTER TABLE ONLY public.pacienteasignado DROP CONSTRAINT pacienteasignado_idpaciente_fkey;
       public          postgres    false    2933    211    227            �           2606    158280 )   pacientes pacientes_idestadopaciente_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.pacientes
    ADD CONSTRAINT pacientes_idestadopaciente_fkey FOREIGN KEY (idestadopaciente) REFERENCES public.estadopaciente(idestadopaciente);
 S   ALTER TABLE ONLY public.pacientes DROP CONSTRAINT pacientes_idestadopaciente_fkey;
       public          postgres    false    211    209    2929            �           2606    166929    pagos pagos_idconsulta_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_idconsulta_fkey FOREIGN KEY (idconsulta) REFERENCES public.consultas(idconsulta);
 E   ALTER TABLE ONLY public.pagos DROP CONSTRAINT pagos_idconsulta_fkey;
       public          postgres    false    241    2967    253            �           2606    166939    pagos pagos_idestadopago_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_idestadopago_fkey FOREIGN KEY (idestadopago) REFERENCES public.estadopago(idestadopago);
 G   ALTER TABLE ONLY public.pagos DROP CONSTRAINT pagos_idestadopago_fkey;
       public          postgres    false    249    253    2976            �           2606    166934    pagos pagos_idtipopago_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_idtipopago_fkey FOREIGN KEY (idtipopago) REFERENCES public.tipopago(idtipopago);
 E   ALTER TABLE ONLY public.pagos DROP CONSTRAINT pagos_idtipopago_fkey;
       public          postgres    false    2974    253    247            �           2606    158443 '   recetas recetas_idpacienteasignado_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.recetas
    ADD CONSTRAINT recetas_idpacienteasignado_fkey FOREIGN KEY (idpacienteasignado) REFERENCES public.pacienteasignado(idpacienteasignado);
 Q   ALTER TABLE ONLY public.recetas DROP CONSTRAINT recetas_idpacienteasignado_fkey;
       public          postgres    false    2951    229    227            �           2606    158352 %   respuestas respuestas_idpaciente_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.respuestas
    ADD CONSTRAINT respuestas_idpaciente_fkey FOREIGN KEY (idpaciente) REFERENCES public.pacientes(idpaciente);
 O   ALTER TABLE ONLY public.respuestas DROP CONSTRAINT respuestas_idpaciente_fkey;
       public          postgres    false    211    2933    215            �           2606    158312 &   respuestas respuestas_idpregunta1_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.respuestas
    ADD CONSTRAINT respuestas_idpregunta1_fkey FOREIGN KEY (idpregunta1) REFERENCES public.preguntas(idpregunta);
 P   ALTER TABLE ONLY public.respuestas DROP CONSTRAINT respuestas_idpregunta1_fkey;
       public          postgres    false    2935    213    215            �           2606    158317 &   respuestas respuestas_idpregunta2_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.respuestas
    ADD CONSTRAINT respuestas_idpregunta2_fkey FOREIGN KEY (idpregunta2) REFERENCES public.preguntas(idpregunta);
 P   ALTER TABLE ONLY public.respuestas DROP CONSTRAINT respuestas_idpregunta2_fkey;
       public          postgres    false    215    213    2935            �           2606    158322 &   respuestas respuestas_idpregunta3_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.respuestas
    ADD CONSTRAINT respuestas_idpregunta3_fkey FOREIGN KEY (idpregunta3) REFERENCES public.preguntas(idpregunta);
 P   ALTER TABLE ONLY public.respuestas DROP CONSTRAINT respuestas_idpregunta3_fkey;
       public          postgres    false    213    215    2935            �           2606    158327 &   respuestas respuestas_idpregunta4_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.respuestas
    ADD CONSTRAINT respuestas_idpregunta4_fkey FOREIGN KEY (idpregunta4) REFERENCES public.preguntas(idpregunta);
 P   ALTER TABLE ONLY public.respuestas DROP CONSTRAINT respuestas_idpregunta4_fkey;
       public          postgres    false    213    215    2935            �           2606    158332 &   respuestas respuestas_idpregunta5_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.respuestas
    ADD CONSTRAINT respuestas_idpregunta5_fkey FOREIGN KEY (idpregunta5) REFERENCES public.preguntas(idpregunta);
 P   ALTER TABLE ONLY public.respuestas DROP CONSTRAINT respuestas_idpregunta5_fkey;
       public          postgres    false    2935    213    215            �           2606    158337 &   respuestas respuestas_idpregunta6_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.respuestas
    ADD CONSTRAINT respuestas_idpregunta6_fkey FOREIGN KEY (idpregunta6) REFERENCES public.preguntas(idpregunta);
 P   ALTER TABLE ONLY public.respuestas DROP CONSTRAINT respuestas_idpregunta6_fkey;
       public          postgres    false    2935    215    213            �           2606    158342 &   respuestas respuestas_idpregunta7_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.respuestas
    ADD CONSTRAINT respuestas_idpregunta7_fkey FOREIGN KEY (idpregunta7) REFERENCES public.preguntas(idpregunta);
 P   ALTER TABLE ONLY public.respuestas DROP CONSTRAINT respuestas_idpregunta7_fkey;
       public          postgres    false    215    213    2935            �           2606    158347 &   respuestas respuestas_idpregunta8_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.respuestas
    ADD CONSTRAINT respuestas_idpregunta8_fkey FOREIGN KEY (idpregunta8) REFERENCES public.preguntas(idpregunta);
 P   ALTER TABLE ONLY public.respuestas DROP CONSTRAINT respuestas_idpregunta8_fkey;
       public          postgres    false    2935    215    213            �           2606    158482 2   tratamientos tratamientos_idestadotratamiento_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.tratamientos
    ADD CONSTRAINT tratamientos_idestadotratamiento_fkey FOREIGN KEY (idestadotratamiento) REFERENCES public.estadotratamiento(idestadotratamiento);
 \   ALTER TABLE ONLY public.tratamientos DROP CONSTRAINT tratamientos_idestadotratamiento_fkey;
       public          postgres    false    235    2957    233            �           2606    158472 1   tratamientos tratamientos_idpacienteasignado_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.tratamientos
    ADD CONSTRAINT tratamientos_idpacienteasignado_fkey FOREIGN KEY (idpacienteasignado) REFERENCES public.pacienteasignado(idpacienteasignado);
 [   ALTER TABLE ONLY public.tratamientos DROP CONSTRAINT tratamientos_idpacienteasignado_fkey;
       public          postgres    false    2951    227    235            �           2606    158477 0   tratamientos tratamientos_idtipotratamiento_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.tratamientos
    ADD CONSTRAINT tratamientos_idtipotratamiento_fkey FOREIGN KEY (idtipotratamiento) REFERENCES public.tipotratamiento(idtipotratamiento);
 Z   ALTER TABLE ONLY public.tratamientos DROP CONSTRAINT tratamientos_idtipotratamiento_fkey;
       public          postgres    false    231    2955    235            �           2606    158254 &   usuarios usuarios_idestadousuario_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_idestadousuario_fkey FOREIGN KEY (idestadousuario) REFERENCES public.estadousuario(idestadousuario);
 P   ALTER TABLE ONLY public.usuarios DROP CONSTRAINT usuarios_idestadousuario_fkey;
       public          postgres    false    203    2923    207            �           2606    158259 $   usuarios usuarios_idtipousuario_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_idtipousuario_fkey FOREIGN KEY (idtipousuario) REFERENCES public.tipousuario(idtipousuario);
 N   ALTER TABLE ONLY public.usuarios DROP CONSTRAINT usuarios_idtipousuario_fkey;
       public          postgres    false    2925    205    207            �      x��]�r�Hr}N|> �	^c�&�=a��11~����p����O�7̏9�UE���=M� Y��"���̓'/UA�vw���n���M�]�;l����T]Z�`W��]��~������tWt��}��K|U=�mZv�x��k��/��o�r��ֻ�l3�J�*�ʹ��ժ��w�}{������*�/o���論.��T��
����ζ^���ޥ��U�6}j��j]��78��L�f�ߥ��k��d�~�\튆ߧ���u�sl�uZ7�*��u��p��	��۔�����ht����`7�C��8I�N��T��8���׫U�m�]9K�U����>W]Qf|��J�b�"�����vZ>�(7Ŋd�o|�tW��u_����i۷�j�k���?����U�lQָ>���?I:(m|�!��-��7���r,�Fү:Y�~�5ժĕ�۾l�t�?�
T��(�̦Ɓ5��������8�b�W[W,�t]o�f�vE�6��ʫ -?Jp���zז(��f��5M�6��SE�l�jx�r+?3�H����0KRAZVr��Y���(��������8��ߪ5�k�kŚ���K����7E�*��H�;\��b3��i�F���H��`G���Q��c�5E��U�U���6��.aQ�^�N����E�)wi���+�-�O~5�u�P��?��(�@
�/�XTۊ�u�#k�����jV=�$�\��j+Բ���5r�䭕����t��~�ﻢV-xKu���[4�~kJ+���ר�z��_����-��L[��l�ռz.MP�>��ef#81�ɲ�
��̛=-j��^m����|�c�Bhd�7X��١�2	Z�5�!�NI�x���V�䢚���G�}���6�y8#c�1;���~P�q0�����'z[����{��gѶ��[U람���{��&�R0�A���YL�ryZl�C}F-��n2�Nؤ#^�2���uD�u�	�ؕT���F�2�prTF�<����}v�xQxG��в�u�*�&�i�q��U�v
N�IJ�Ec��"�+�QA��z�w��s"��K>�'�t`���o�'^��]��rg�V��SXΒ	n	�M��KCu������%������L��C1C�Ůh����_����Uhsm���������:�
;�U�4��B?Bw�Q�}cKox����oN���_�@�Y����8I'@j;2�p��$��<�eF~�a�~@4UN�������z���5����%�VN�ҕ	��3��xBtA8ǎ�ڡ�VB���bC�	����V%M�fڢ���3R
��T��@Ƞ_�ř�!B��4��}౞��!i8?nH�LVI���9¤d�Uz��C�\=�m� �K���bc�4�e��I�F��^��;��9{aSR6�i�Q!F��Ղ�(���ru��
,�۬��`^J��1�]ٙ��t����<�����B��0b�hWȉK7�M1�ϊ��)��%m|�~|�
W\����������4Fi�^Yb�~�_TW����0�p��y2���=�FUqЮE8��*�  �����KI8׻pJ�馞�$az����� f�H��xVY�I.7"���0Ĳ@�o��������E6�����X1O�aK�d�����(��~Q��#3�u�⟜�sv�$��Q�&�*�x�x�NWAÆæ�K%���ٽ�f\�𫢤JF��2z,�⃀�y ��u�i�` t�d,�-) �f1�G���C �v����]�������qH��b��!�N,�=�ڿ��K^�G�Kj�R-Vb�碩4�⡇�,x�K#8!��1��߈�R��m}���3��$��$�'�=�
{k��ޖ���L��ަ	��*�؊t�7��u8}����Y�K��X��~.6�6X*b�6�1����X K�Y3߁�8%l4$7�Q��RKR�r�����A9��nE����('k
�]`�rj���xN��x�B7:G:h�����(b ��� z�O���h�b�b�J�j��*&s�Y�Wߑ��%� ֱK��9C��L\Wp�B�Vb�y���$�I����d	� wcQ_�gb�ڙ���c�8EVk����Σ����C.)|�VV�A���I�X�egD����rA15��s9t��M�i�U�Q�UOǭ��|�i����hтC Ao��Gİ�0T�kX��W��I�A(a�. �G`>�k�����g��dƫpp�>��)- ��rڑ�g
���<`���5�ar$E�}��y0q��R���vpQM�z͆�9�Z�O;�ew#&?�9[.]�1���Y%�̔,!�$��$�R<mF{W8x�`�V�*K�8}�/E��xv�X����Ԛ��9D�N+(�=a��e2�����H6�!I�/���ܱR:�(���r ���CyK�s�N��g6��o{�|[��g���ק5&�ϒQӊ1�x����M�c��	\W��;m	�I2��	:7�pE݋�M��c�"�/$B=Y�2LLG=�:�˙|�=ӳ ��Di��E�n��U�B���U�������ȃ��\8�J�T��-��_�'���p�4P{�.�k?��~Cѝ��Q��Fe��g�Q߅\2pqH\����e��fp�}�p�,�-fC=�n'v�Ɇ�q��M�z�,�Ug_����~��ԍ�p!��*�^p�X�j�%\y�tV�0��V���-E�x|>S��ד�uk�F\������U��墜]B�/8i�(�w�%Qŝ� �:;=��X�țnC��������(2=�x�J*��ې�Y8_[���x�';W��w�[0��f2�	�
�e~��[����̽�x��٪_���-Ql]�K�U���VUu�������>��>�҂���̓q��E$~Pٮ��pNt՚ ��Iv϶��c���doe\\?�$uX���^��譚�^��(x�x�U�r���!��c�c��2ك<�.0����$z�r�����I�!�c�5���G.,iu�� �s�Q�z&*��X
y�B��[|�w���7M���
��ȟ6��,Oa(�y����w�٩wL���]�����בt��%]�<��V�]����1�5�q���whFl�����aܖ��а��:������h�#�M�xq������@v��~����S�0Z1b�g�X,���e��/�k�������;-v�}�6�p��������U�N����*<�ϕ�[p�J��ꙝ+��zf��D`�̾�|��<E��+�XB��	_w�� [�8�+gH౵t8��ap�)JT���ϳ�b�X��!PI����"������g�I>�6�\5�0N8
;iQ���hR����b`iJ2��v�dͥdJNY�
�F,3J�	i���yJ�
��7|�[.��uu�h�OLQ~�`!��3�L�_v;��֥x����9`Y��;mm���Ceڜ*��8��0�4�<G8� b1/f��`~��9�'�o��]@�LP�Hhe���p.���8��,ɧp<PJ28�����0�'�.�
uf/���� �I���}à�;��w��yl״��:���~�>��|CՉN~�X}�����$_�Mo뺵���V�j�4����b�j
p�%{�<��ip�Rں!Y�Sl�̆���0B����ilž�$���`:I&c��^V���_��-O��!�rQ9��z=[b_?�h��Wwe�����8pZ�̻,�_ww2H���4����Q�V8ȓH�VD|��7�9��p6�{;�5�������
 �U9� ̭m8�����w +�ƱB�D�4�7��n�G7]H��N��� :�W+�?���d��!5
W+���KO>p��P�b��[*_~gڸ��(|+�\�ݍ�؆���ڋȣC�P�� `1�+41�j"�" �"z��&�\��].p�}��A�*0N&K����j�Eo��<��Cl�Pe
�؛@[N�#�Σw�X�/�N��Ѓ2,���PXQ���B�ԓK���{� �' �  �|g�b���21�$�1ħ��Z�`kG;Y>>��z��0C:��u�]�/\ c���0�BT[�I�Ai]x�2t5|V ����v�+s�XiG��v���em]�-!e��e(�h���k��?��W��
���7u�M݃��7�gz[9�2�5]Da*-6����<�&wU�!#�>��QdT��ۢ�r�G�t6�e�݀W�.a9M�s����v�/�-���f��朂��!~;'�Q��ID	� i��UU��6]g��q�L3����mc�p��Y2]�P���X#�
�	�&L'�{��݀��n±����}j\�Y�}I���
{�5I6Ur�j��@��18�98���d6����}~��àv��n'9�C֯�T��x/c��l�������p˂��>y1�8�P8�_>8f����a�'�	�������DE�u���埆���X���`_Ϝ��c�p�͐2��@�a�.g�>�[���s�����nVը�g6�[�n<��Ի�M�'y.���O�2��jwЉ%M8�Oz����S�d6� ; �{1^ߋq��I���#,, ��!0���@����ɀ�"!�$�%�z�ue ���>�Q�sj���M[Or>�|�/��.����\�מE��|���Vt9-�B��*�k��/hx� &؜H�فEr~J�Y�o���Ҩ�9�mĭ�95}�[�焔S��R{�%�ڶ��N�v}��W�R��ڃ�`�L�c�nk`n�*��|��s�; ���N�+�׉�u��K0͓��ZcL��4�
7�!}���Y��͟N�>r���U�v�9U����S�1u:���wl)������=��e~��꺧��7Դe�4���˄,H�E�F��R
��ȸ�t7ʁB캵F"��U ��k���B�ð){(S���	m�Y���Ȏh�@Ϗ��vZ�G�\U�{c��S���ڃ* �6�zj�Q�E��r�����ԍ��E�>�2��"�/�*qs�YSpS~	�q���$�c�� چ�|x��r	&=c1���'ń@Z�Ѽ��=Ɓ�=�g�����O���X���B ��[ۣv��br"���;��ƖD�hU1��TޭZ��G�"��Y�v���m��l�6���b7�Un��=�͏���\�2�0�5m�|�(��H뜎���b�,�;�n+���։}���zNѽd���Ć[R��Ռ�й�G��N0I3��|K���k�m�f|QfL'�,�[?��{(*���d��+����&��{�l>j\޻�]�F�܌�}�dC>K�#p�[U��Ub%>����У��c�&iA<o����d���ٝ�yv���DG-'{|b��W��@dW��.R2FL!u�G�@�)�����>Y� z���0�)*L���LD���]��׶g�kM؟���5����ޝ:Z�^�
#�V����E=E+�l�\�ؑ���l]$D�0[��S擘�l�C�7���W�ޱ�b�h�5dZ~C@�0�QT�%@���{u�V@�6I��~Q��S��A*��j�`��a�_�/�:�=�6^XL��.m�*�pCIL��C��`�'�|�# t[�`��G��7�I=Y3<��d����j�y_�_��d~-pGC� |`�X&��{8}Ī۴���Ϛ�D#����FFТ��/�Z�'�_��54�~:��ykBo��.y�������c��ß������/aTL���~�U�o�w~����-�b�{L�j�����[�!��_
F�Sޔ�WЕR�ǿ� Ӡ^�5m��_�;3��ӟ�����������?�;���w>�&�>N�x|L��#I���Y�H?~��c*��R���/������|B�<���#��xW�]�V�����}a�vĦ�c7m2����SOF��߂OC��.����y�y�r�\�EH�����#e�R����'��S�<
�[㒤������7�0��4.̦��(1H����������kz��?�e󌂐�%��%I����t      ~   �  x�E��m�0D���,H��F���p�<��g����-�������Zꛞ7����_����]le�>�����gy;�O>��V����:z[�Ώ��������x����O\��~��MOyS}��{���k���E��.C.�\,��rq�����"g0r ���>��_�;����p���v�7x́gx���x��~
OI�1(�(�����Mm)h[A;
zQЫ��(�MA�P/�PЧ������(U�x��`t�O�bLc)[�8
fQ0���(�M��
�P0�:\̥`n�(XE��
֣`5�+XC��
�ߵ����`�*؏���`{*�K���|���S���<
NSp��3���,g+8�J.)�;ɏ��7U�-      x   b   x�3���L�L�KU�/J��2�N�+�L���LIL��s����gs�p�eg�$*$�(���d�$r�q:���� �Ab@�.��7�ø1z\\\ ^!�      �     x�-�ɵm9CǺ�Ԣ5��m?�8����^��v#��Ӣ0������	�����@�iJY��
7�+��V��=L ��GCEK�,��G�BZWjI��G��:��$P���S0W� ��>j��r�d�1��.���O����K�:�k$���T-�!+�������)�f�%][����e��&��jJ8VeM��s�]�v����%U�ݬ�~��M�S?-X󚝪50�ɋ�b���	m�>>�'��<b��<9�:T�),��v����!���`�Z���]�dbV�m���4�[:�Xe{֜�D��L���Z�W�����A���I�ʓ�ͼ�{}� �Ne^uy3oF[ɲ��������D      |   �  x�-�ɵd!C�L�g3:��}%jS� ϒ]��j�g��Fm�v�lq��-������n���j�����{D[�5��Z�@Qh����z�6?�P�J���c&�Q����O�u�̶�W�v�}�\-�쉶�ϣ VO|K������y3x��>�,��6�֩�Ӈ�cݭ��OKE<�H�#t���M�����3I��L�@�;��}���*�y�<�W+��^l�|���꒶����d+D�b^��cY��m����oJqU�P�o~t<��ԮT>U{��~�����}b%3��8��P���N9:�����{������ǹ��m��{r��NF�Aٗr��)9����d�ɹ�S��jIF�rOl��-�=;��B\ūe�K�\��R@xz魭s֣��N���*�����Yۂ�g���oĀ��GL�G]|�����+����~CҌ�"�6)"�N$�B,Yf�j�>�!< ����	���i�Û0pBu^ހ�ŠM��nP����97Ev�B�I9�h��Gƀ7/*�#в��%�T����QH��İb�# �� V3�Gu���	�����c8]t��܂E���_ɨ�p��)�F�d@s;��dP��s�TD�|�VҐнF�ߖ�CJ��^�� � uT�ġ�]�m�jC��j1�΀�i5��4.]#��N+Ʒ��"�����q��;����U�,��7�\s%���%9��{.T3��'~D�\���\�q�M��E�k�Q�1�Y�'K��c�w1��oC2�SC�����ûR�޽u(��FM_��<�N؜���wÝ������Z��ԣ*�S)�$w�}��$]A���C�|ccR��3յy����K�Γ1!��_�z=2�0�GMӰn�q���	��W��a'���P�ƴ�Uz�u���%}"�盫���$��i�\�_��P4G�� ��[D'����������|���;r0-�%�����0�]s���&��cm�b���M\(��ɈBx�ߕ��6S#[���J�xӏ��D	����@a)�.4ăE:I�!,�Q�ͩ��2� ޳��v��}}:!�5�{�	S Ox7\j^����O�'�%Uλxg��?Q�I�lJ�g�$�xv]��|��Nq���&x���_c�D<�h�x�k@<�Ɏ����4��C��ӟ)��,A��Wv�N�ouR��7T�����|T��      z   �  x��XK��8]ӧ���H��xW��f1�0��0%�Ɂ-e���;�)�b�"(;-:k��(U"��/"^<R�ZL�sS'�,WB�Z=��	V�P�C��b�r#���o�y�T�lh�����V�o�J�����,U�WB����-?�%U�K�*Ѫ��#��q��|�p��$3y�NG|��i�����a�4���}���3����Z'L�>�r�X��$���i?9�,�v���\�����˕X#��~=X}ݤ������ZEC	�:IPp��v1ʬ��/�g��I��pp�G,���ԧ�cު��h����?�l��X*����]#�a�K[��0Ukei��~9����S���6k�[�*���iY*�B�R09Q<&K]w/��y�����''/_�|];��u�>��ih}.���p��I-��r��O��ü��͟�ٷ�2e�Q<)#r8ZƸ
��{ˁ؃) ��g�t���\^�Ԇ�t�����K�@ �]p�L~����n��)W�m�"��lK.�~삟%|i��3�y	����k�!�ydx�'��<��3�F�Qx�}x~ْ���9X�F��iA��W�� ^�!��vD�Z��Q��6�WO�dtP���g7����{s2C�����)��o�����kZ�g,t���B�/��(�E#�ֈe�g�&5dL	VE%iū�|>���i���BdZQ�����AO�r������Xo�`�1*j��R�k��x�d-��<��O��gxs�:�}���p���"�ll�Gw-U;gV�}8���oav~�,X�5�D��&���ɟ�\s
��9����6�T"59/�	@+l��aEmhi7�b�CjԵ�1��X�
*���e����ZH�$VR�Q���)�;b�Ɉ44z� �bĎni�3`�6<���T0h��\�E\}뺎�͜�h�яx�$l@_���4�jI^��y� ���]+
ԥ�]�R�ɿ�sx�i]0�
h��:m�V\�<zh�B�nj=����.I�K&\*���@G������ ��͌��xHôr���ǒ��Ӽ%���m~}�/�܆d���kY��X;X���O�K�=j�Ӡ��C�e?�۩@�Vq.1�v(��3����D�N3�OJ ._E��[���������tl撜��Ѣ�l��eAF�x�t)�W�̩ȸ��s� _���Ø�`��TPF�b�-��A1y�����2�m�TJsN�d D[y	I�h�3ږc�D�֪����R՘Z�~[V���8j+��!�ټ&����Z�~�������*f�`�~j0'��`��h��>V��%C�T|�[� fPy��8}��î,r��$AL�b���L����P�������i;�,�&��f<J��e��,a�8��8@o���܆��8"u���i�D��y�$ے˼"�	����HW�iD�b�1ɦ�Ú�Ɖ{�`I�
I�4u��e�b�
���?�?���5��DNӹ��N�I���?L苤�5)*@*!"�@b�=I[� 8�Uu(�J������UX�¡�]�wT;Vm��5�Y��C�[��wW�W�YH^��JP`Q�e����RX���Lp��Ƹ�(�uV�m���h��r9z���XR5C��tG�ރ�Gs��ӡ`�#���kO]��tL�<�����G7���Z�*�B��66a�0\E�YP�*��ڽ|������%)Y�"*��bSҙ9�� 9�]U��t	��쩉��$B��"� #p�C�#�r�R��������x�RӲ�,�j%�r}����Ȓ�x
�ԗ�wH�zp�&�3N!��hy��#�J�	�T,�j��?ۖ�*W9iH}�v%��!��j)��]���
D�mr�4����b��,��ַ��6��5	m��(k�Pp�v�| cN��������P�Q�>
�;������J��h�I*�>y�>mS܎{���4_x�Q��ƈ{�._�1=� ��%Nk���y=�@M�_��H�G{K7MyS�� �+�i�zM%>�GtI"Ċ�"�!�\ޛ�i�m�HKz�4P��ւ��\O�tهC�	�M��L�Kloh�*��x�B�Jǣ��4�������P���]کc�}#���?}��ɋ���?z?Y��#p��+J���7��驫�8+|�v��8��^��W >�l�Wh� ���.��w�9�u����r��Fީt��O�a�^��p$���.�����ˬ�e�N�l�*`�����_�n����M�      �   c   x�uϱ�0���(�$N؅
�	*� __ut����8�OΉiJ�ذ(%��B2���"��
	���&��j�"?L2D�]���E�X�j����3u8      h      x�eZ�v�ȶG}k�;4,E#EhFo0=�v݉J[� ���,�׿}B������ivs��58�et��ӕIGօ~m��k�����`��y�hm��#���s~m��s�v�8<�H��=:��F����NY�^���`���x��y1�`#��o69�4��f����H�=��6ṶLp�=����̮ތ�,LO��G��GAVm���5���C���p=���a�]$��.8=Eq~3����ϟydam�5�1\�57.5k\��8h���g���5l�qt�DYx�L��1����v���_u{��{F�� �K�lޘ5j��ߚ'ݧ�υ����n�}� :��K�!x�*��8��mlP�v�3N�q���a��b�~����$��|����(bQ�(��!����˅���i|oQ�Y3Α�!�������Hbxa��	���A����c�0�������-�+�R(�6����t]�.������8z����w~�6�l���?d�/��	�V 2�%*-IߢZ�+dw�:WB�c_�c�P�i38E������|�[wR�f������dQ�կ���Z�=17��s_k��ǨQWY��3*	q+�qI�g���;��y�k,�Ut�l�$�aZ�B���͓4ˢ�̶4��#��Yî����69&{��u�����t�-��Z��߀��q���Dm��"B�Gԍт����������)��4��.U���h����և��9���,�$������(���cu�.�1��zʰ<���"����$�/����_��P߰Uw$��b���G�u!ۭ�W����|�Υ4�.�)2�s]��ɢ���h�f�Gp����5G�?��-���N��hN�l�#4R�#O�ȹ�#Inm۝|�upJ0�ݐB�ʵ]B|��w�ol;^8�x1���E�>@�M���C��������.6M����g�{�(���� �,�ސ2g�mO��f)]���Va���'��u��a��ײ��3��x��t[3{b�M_��n,6+:��^�녺�|E'J��p�5;EI�Gh��Ǒ,h�1�(�R"�Oct�c.�/��0�3k�O��b��( ��])%���t�_w���[��E�]�I�^j�r��HAB��R**����-�nA[�ꋏ�l�gǏ(�*}�
ռ6OaQ���M]pW�Wlv���U�����"��lܞ)3;,�zI�l�ǐ���O��|��Z�x�/נ*&���Gר��s X��&�_�a��؅v�.��z> :t�����
��N����.��a�'�t�r��q��捊����#��W@	�bx�S4�-��������]B�{����+����^Ɠ��/���F]h�|�&Q\E-A�eQ� wl��-����V%�l��O�׭K�+�%Z�
���+�ӥ���$
{l��_M��MŬ�	�.I��	x���1V�c	�r�V�%\� �RLZ�>U��Q�i��Ӆ�/��BB��F�b;<�y	-�j��~���>a��X�7J�]��,�,�u��z�Eo�3���e��x���0����p���^m�٣D����)�&���"����G�	�OFN:�Ӧ]<�H�M
������B-e��z�W����9' it�dB�6JJl��)�V6r�����t�6�J#�Q�\�@�үC�8�Um�|96�H��4m�XX��mz��?������pO�ȣ�(����%'O�}Ϣl�V�*��H�|'²����Y�_*v/�r��=�1[�^�3{,mV|�9�'YFJX�B�T�S��Bk��b�d�bE`Wq3��0�z�`f��yz��;�=v���
Y�̯Ծ����˹�u�����%CO�[�+N��[���,n�:�{���mw:�M��)��,>&ǟL��w~���s*5!�X�@/#EY&�B�2X�<���:[{#�ZooIK?KU�����q��R]��"]���1Űy���W�Lٖ.{��p�_�I�Z?Ch�n�˦����&9���U��}�E�!�?�I3̑��+	��p��ζ�0[��RQ�HRZ����0#O�/ϯ͠��TE�_�f+�QǶ����0�D��˭Y�L�y���I��Y�X�����K�@P ��e��p��H� �tINM*�r��������}Ǵ�t-Ϻ!�6��0�p��j��jRCq�da9c�����uUpS���Ƹ��ڬ'tv�^Bd?5���R�^VF	��|Fr�1�c�s�����v���;N��NmX+�>����)�(^�W��Ԋ��oB��}w,NNb�M�-�'�9&��>�#�gt�k��t�'!�\�^�W�J� O��=�$�-%t>���u���k[�	V(�#:��u���������c��#L�?y���u�|�J���0-.�v���_�oE���`J�[����w� �aWU���8����8k��i�X�.�mV4~ [��)q/]!���Z�ED[�N�~+��瞮u��1��i�CK��Ybo� k�v������u[ʴ�KaU����B��8C����<ϔ�U@
���eF�`��A���0�r0��=a�Rl��o��и�	Ƶ���C���A�e�A��M�Un�-'}.˝n�(���2'�M?�$rt��6�z���u�ΆLhX"lXo>h���7�ǆ���Y�YhI�M�<`�Bi��7r,#$W��|%#�ռ	�ǂ*�/�o�J>O������l�\���QPPW���R�c�.�Р���Ƚ�V���T�,�j��r�QK?�J�^�5>'�'��rj����#���߰uiTK6�)ߵ�����Y�]w��P�P�T�4:~$g"A3@�c9���cd%~7�Y��0����M��꾬y��(�y/�Y�������\�F�oK ��2�}&W,6pn�F�1����	�|�qŦ5R�FpsB���,+ݖ!�,�U�ꑼ��!�o>�Q��*Av�U܇d�r�v��n��>��8�I�.�������_�}U�w��u�-�G7������0Qf�fQ�f�jD���^洝�����=n�	�T�]��**�Ӆ��G�����|Fo�ݢYbI�,�ۘ��J��뻺���	M��!��Mx�~?��BKID0�KjdV�q�ոOD�(t/�b�֚}�=�֔��EFp{D�װе��w��L�BcA��I~�~�	����:	�'֟�����r�9%x$?~\���x��qml��T���\�Fe�>p�b-T���([�v�ә�Հ��#�d�(<��� h��"�e�<�֞���"f��{��ϞX{�f��x���0ج�l(
 .��h �F����1�>TM1�iF7g�]w-հ���(9	6���NA�pw�Vx�Jq���#�59�jX�o��� �[m�V��"���wg����8�#���8�3�]W��l��)�/����!�ڀ�	h2��&�`���b�{��y�+���:N�Q���B�WN�����H81|ۃ�i���4�;�7�hO�jN��h��!��sr>��t����C�lq�T��x,\I��Ħ5�Afe��rM�sOO&[�����a����Ϗ�6�j�7�@�̃���\�"&��9H��J��:�:Ϟ�vr4�[���	?̄��
Na�\m�Zp���4l�����,����l�l�j�^�C��w��,��U���F׵� f)8�|�� ��V�c@a� �m��"�ٺ�u��r�^h�6R�s \m@h����-<�#@
«�I��ފ,iY���1wg��n#ڤ�<�VP���2���) �P���������N
����빔��N�h&��2�����Y!���y|*u]� #Mm��fG���J�"F�ʝ��� n*�M�ӵ�?5��Z������4� �q�E��B��*����N9�VG��鴃bF׳n�+~�HP�]RZ��3h�c\ �Q�T��&�/�����4���=O��+m�����2p���ו�u��>(L�M2))�D�o���ճ�t���z�E؄�}I� [  �{Jc	���9���9)� 8�	�Jy�����%��0�/��'�?�4ֲd;�FAy�!Q�@JR��h]�u��+fUFI�iWY�uva�͂{��TnI ��V�����sR2BBh}S�������ϲ�eQ��Fpj�L��,'���,�5\w�y�S�M��]���P�8b���b���.w���ˢ+�X���2�R���{�^�==�̘�O��V�'z��������Q}��۹ݝ�|y���u�����3Ț<N��B��a;s��˻4�֚z��M���]�:�~�Ɗ�gJǣ�X˹$n��D��Rw������:Ϋ}%$��BA�~��Z�=zɻ���8�����,Z���e�,��uXx��=��˭qX7|Kh�3������+Mp���t��L�7�\T\~�N;�w.��_�ҟMF�晞"����U;�	�+\T�����XU�ZqU���X�K`�|e [j'�c���#5"|�[Y���������� �sݍI�6�a%LT��{P�^��9,F�l�is1߷����H6�`S�)�%Ɏa\�8� �3%,�7
�Y��d)�P�|Hr��f&�~	6��ꊵi���zYy�r�<�=�������g�
 o�����{�}�j�r���Z�S��˵[�����˙3=�	]�)��j��^�C����rA�>eѪ+zv�I({u8]�����SFRܻ�O�1I^7ƶ��l��
�\��%���ԕq����`���w�T��4©� ق��R��g���P��l�y�n�y�w���a���I�=�f��j�wd�֬@P���D�骬�~6�ݧP��ʏ@L�+��K�G�d|6;G_�F�g<\��XQ2,�/ �4�-�*�)o3YO5yY�&�;�"�������P(���ّO<,ϊҵ���t���v��ݶZ�}�9�NBF�\U�0�[+��T~�E�s8���X��
����(��f˝T��B�[�������ןfƁ�1{��n�1.���	Z�k�����n���ݡ���$�����2Ҽ֯^n�z$�4�ej����[~���C������b��|?�y#b_3ӌ>S�:~\�S�< �ä�ʸ��p����(�����c��%h�� Zj�u��>n9Ә�	����*��ȗd�0oZ��쑫�I����L9����nF[x�8�U�(�k�<N�<bOHQ0�_ԽURA���v�|�z;�����B;�dK놯��s�g��u�<A��"���wWȳ�M�>��tvR��+�KSd�����R�Ar�t�K��g� �>���}��.���(���r��s�qV�ggM���lRt�I���ZI.
un]����y�"E�±THU<I./R�gk�kُ�T�|�T��o���qJ�T���~@�U)�����܏]ȡ�n�O@�br3�uL�*g� �'!\��z�G�s��K���W�r�E��o����f�����w��S��G��������يg�#��}]�c�A[���t��Zv�~󳈔�OX�:�?��4<�xC�_�f�i7���m�wb���-N����d�୧J��=~ ����_�����h      f   �   x�3�H-��O��+���O��2�t�K�3�K��9��J\N�D�r�JSN���Ԕ�Ē��D.3N�܂�D�Q��&r�C�@�
��%�%�ɉ\�N@e�������@y ���e�R�X,��S�M�� ���B��@�b���� ��G      j   �  x�-��1C��b��!������l��,$[4e��g�R��Z1Wq����l�Ƭx��^�������+9�H%8Q��|��1&��t�F���X���z�x�{3>�3��xvM�����d4�k�(��:���i�k�O5S-����|�2�*dCG�o�b�����-�nk!�����,j�ǂ�����~�����ϧ�����=c�^>ܧ�e�"�7\�q�u�ٶ���h<@�s��S��j�Diɢ(�u��;���~�!�:���o���h���ĥ�]�1=�\�<�!@Ҽ�a�[�Β-¾b��rξ8��M�P���
���j���;�B�c�M�����A�ŰM P��~;l���J�+�����#�qRo      d      x�3�tL.�,��2���K�0c���� ^��      Z      x�3�tL.�,��2���K�0c���� ^��      �   2   x�3�t�S(�ON-��2�t��K�ɬJL��2�.-.H�K�rb���� 3�E      r   2   x�3�t�S(�ON-��2�t��K�ɬJL��2�.-.H�K�rb���� 3�E      T   !   x�3��HL���,IL��2�tI-�@�c���� �f
P      b   �  x�U�;n1��u��ﾄO�d-�8��#S���j�0�,����󧰓~�#N
�I�:��'5椁�eA�Y ʬRbb�r���R���2P���tU�tU�tՠtաt5�t5�t��t��tu`tm�����~�����9����%����5����/8]8]W8]���~T���������������AЍ��������{��8�n$�n�n4�n�n.$�$�T$�4$�t$��s|9�t��t��tsPtk�薠薢薡薣�V��־A�
�n5�n�n/4�4�V4�64�v4�4�N4��w�^�F���Н��;��;��;��;��;��;��;��;�5nm|�ƿ��ͱ�˓~y���v��[ k7ˊ=��|�������������{���3���������ٻ�i�
Z���-���i�Z���	��\o���s�]�8g�����p      �     x���_o�H �g�S�t�3���8&P%���N����$��.��	!kc������Ɍggv���n���j��F���	J��@���I�HB"I��R�~���h&����(P\)b{��+�x��&���.��{\l^\����x.8�[��_�C2d�#��{ҿ;�d[�?�U����,�a�@o��#�m��hJT�K�K#I�tԄ�t�2Ho��H����V8����0��9VKA���N�j�/&NHسՅ��]0��¢e�����N8H��Օ8�`���y�Ҋ�κ� {���w'��TSD�UnJ��2��<���	e��*7��/�6)��U�e�������c��mm�H�EO��Ʀ�@�$���" ��C';GUE�^!�꥖�� l�IMw���9?eљxP����>M'�Ny�A�${Q�۫h�
;ָ����Y1��]���\ХWʘ��r�L�Q�=�jh �Z�aJ�U����*�����.4�4^�.�^hg}����^�U�W�=��~X�{���$�g��O��������c6���[<��2�%n�#��k�]�9v3+?��f�oC
P���@$��x��M.���7����i�z8��vg�Ɓ�ޱc����WNXwʋA�\{��u�_�Gø�)�ȁX.������m��y���˛.L>r�7�3�r���Q�Ak�Z����2�q�8
���l�X�*���T��q�V2^Ƕ{����:�	i��X)�_31f�3&�<��/�E�AM�=�"O֤��z@U]L�v�� �?D֠u1}���v�/��׳��JFh4z{������m��⥚#�ji|7�!�'�|�ݝL+u�w�j���f9�ϊ��o�P^��C�s�&�}�:�ơ�|��T��h�+�:��O ~�9
���k���N F�e�-�%w����R܅�GV��Y&��T��E=2o�`]()5�Z��t�o֎�un]78���RK���u��.�c�D~��+u�N�NN<�9� ��0�bv�>���F�y6m�r�5ϣ��_E���Q��      �   �  x��ٽn�0�Y|
>@���U�C 9��@i�"��N�篂u%�CZ�g�p>R�)�W��"��PR����!�n8v_��mU?���/��j��s�;����[B�r}�47��Z.��J���Ͷ��|�����^ɥڪ��VFZ�0IQpB��a2�d�-Lv0�a��ɰ��
{I�@N����K�E�(�	�"o��n�v�s?|?t�Z-�ΔK�rM�\�)�e��L�>SnȔ3�fz��iG@��p�����g�p�tO0���?�z�?��Y}�M�ڹ�毲���=L��,�����N_�y	�`?��b2�����Xj6�k�W��5��m��g��~_�9G�`4kM8��h;�C*$[�&3L�0y�dT��7Y���g�	�7Y9�ϛ� =m2�,���&;��0��� ��5ƥ� |Bɳc��Ŏ�L�0��d؟��Q��N	!~��x�      l   �  x�%��u1CϨ�<cl����:�\v=X!��-��=��(��ӱt�t��e(m�=��Sj�i�za��E�]����E�-�lyX%|r�ϊ��z����P��[y�+�#C��F�C#����{���02���5�;�J�ݟv�i��V���0���X��*��������M]�	ű� �Z�9�=h�``>�\�������!�f����%J�t!�k��Ν�}?�SSk���g7����kl�h�1�n4�)>VG(�p̠��>��?��6`1P	 U��^�� ��-<~C������r�w�Z�#�֓v	p�?#E��� ��G��z:/�m$
���b|C)��$	b6C�n��7SC'���\����OCh$�<Q�o�Ĵ�α?�Ԭ����x#�ُ���:F��"�T�Ɨ3��>^�����6Ů�R뽑I!6׾d_���U��Y���<���B'�a]���sq��#�����      \      x��Z�r�F�]���K�|g�G[�ՒZrt��J�0Q �m��fы��؜�	�P�^̸�e�,"q3�=�����joCS��]��b�</}�9S�x΍�5�x����k!y�%������*������C���6�w��1܆�j�_��X�b�g���~�A�����}u�,��\(��ª��Ŝp��Ů�z8v��sW�F��x�>NMSw]?����5�ӱ�i]L�o���=#-%�R��2�,��bf�����}>�����ɒ�����C�_�E۵�_���:~
M����N�qZM��Uݲ�}}{�+ce�N���3��J8�}��*d_�>���ҫ\��dMׇc�����TEw]��?�U֝�x\���M�`�!��(s�q(�t%~Ϝ)u�ӡ�
:�v
�:�s��^
��P=ԡ�=c����]W0�{���e��p�=��8:-#���q�_e)��1�����+Ɇp|}��-F���w�O�S?LÌ�b_�Z��#p<�]s�&rA�(�RkN�g������=ڽȔ�6B�N�Ins��`��`,h�v����8m}}��`ćc�;@��}H���%J���QhnK!��i���f*ڋ;m��h���V8�[�:?,��V�k���?�&�1�Q&�8����
�P���T���S%��IL�����9Ou�]�{ڡk�]ď{�+eIUI�l��] (�79�R�j��������`��6�kՆ{��j�e<�TLpmJ�A-�n�xB�Z%�8�;�.5�#�Â��x��mPī��W�����,Pns��B��Ho�O�0���
����j���HHo��j���8���ڃ��Tj�WZ��+�sD5�@OkQ.�Ig=P�8�
�"3\��}d����B咖~=a�H�8�jO`��x^�f_����?��j�0CU�x=wZ�Y�,�̾M��4Vc��K4 �iپk�X F.�q�ޞKK+�*�l�
��V=�Օ�iW:�9Q�#��هH��9�4��� a�Oc�����C=��ò�w����,R��3J��V+��F��}��%ּm���J��������X?X�Ё%wD,�z������D�	-,���X���R�J�+S
���r�0��.�c"��U3I���:V��>�M| �3�'���V��O�ePj!pl&�],)U�=&pϏ� ����~;�+�J[j�RVja�@eDvu�q�JO��8��`vcT���&Q=S.�٧�.����/���3a9���Q'_�z��@�:�h���\z��-���T-��.���DKpD^i'�����<��qѠ��x'A�B/������z�Sc%�o!($�P�hn�T��jn�����Զ���f���S8�b9;yÏXǶ�?o�V��G_�q|���Ͱ�|)v��I� �-t� ���*(��c�|�4�9��@�?�� I<KZl�@���F�N��"��AƄE/��CB�^ܠY�v�0�o���c
M��
p�5@����%��s<፭ ��<'<������M�D��m=��T�'�A�thu��WS�t���i[�0ᝣĩo�N�*~���8?�����%�	E�exv�9�XmϽ�^\�bR �0N�cAi�ܬg��a��k�4�թo$��Șr5��G	�֡Qe�3:�4E[uq$ܑc:9��gK��&uz�Ww��D�Q��Q-V (k���妒ud���]$����vW#�LSߒ��:AK 䱂�l���J C��aY�֙)_�Ȝ�d���u5�����gc�����Ҧ���]<�z{_����yZ��v����ݟV=�%}T�d�#"��0B����amT���e�H_w��<XF4y-��y�I��\Z:E��E�a+��9z�&<��c�E�.���O����~U}�60-�A:�-R��0��e���T}��m��g��,��n��V�4yv�<��9̍���C:��#3����C����r��|Io�W�˰�K�U4V@Ĺg��2���]���˵�}n��ʪ3郑��X�.���uW@ִ¢�p�RM6�L6a<(on,�ޒ�,�T�zϷ�VzKLұTQ��z��58�����s�z2�τ)���-��HN(>;������U>������M�mE��"dQ-�\�0X�X�6�V��i�#m�����X���2cw֪�$"��V�����!�eR�N�-�d�cu�!'�,�H��O�׊�I.R�"w7a����KgW��:4(s�w
4H�`�d��H鲘��VJj���c�L�CE�A!
n}_���a�|=�9�8��{L��ʃ@ |�T���[8v����IS��r�A�t:X�� z��MSb�����$�?����H��#D�D<D���+�>�8�x岙V��(]�YB[��kln;i?Fr�$Lg�D)4�]?�O�}Xk��
y���c�#�p>��2c@��zo����w��ꆗ}u�[���#!-��c4U�]\�k�	W�RzPaj8��a�X��]ݠӇ3?�� )�� �0q��K�Kh�.�C��+�K/#�s�A1rI�D�W�$-�P�ӌ/Ӏ�=���]�q㡠t`� �_��C�N��(�r�s��'W�0���bk/f���Yn,KƾY��Ρ�q�e�8�tﬡ;��,������z!�y�F�7i<[5s���k���}���Z*��C��-���R-�y���4�[����1�lH{��D��c�chj�0��mq�����5��삔>.��q�D�e��%����C��<N=��:S9���``�<0�����<aGXU�'��L,�����c,K.�'#P�yeb���SNa�1g-l��C�D���\�r%��;�v�bw/��z��*��uݶP�����#t�Bb�x�E�� p	��Y`a�%^�Z+;W$�Iu�����^�<���jf���+(td)�ى݄bp�ٜb#�:��cl�ǂ�j��Ćd�f�a�`��v�w!	ً�����"�bi����ҿMi�b7���R>+ɰ�@34��~Uw��fR`�Ӑ�D[q�]���0K�]�mX��R8�{�l+�h�����ړO�pŸpH����;�q�s�->,���d� �j�0�.%f�ah��z��h���	Ȝ ��˩�Mne��%������~�¸��N�ێN����}����Y8~�Fϸ3zgc��˕��is��`�/�Z����#2%�xW�|�a�ɸ��A����r�{(���O+Y98�5l��Xi�V}`�?UMw��gܟ��G J��z��Lm4wќu�.|��:{G�sן�$؛@�������z���pu�8(�N�fc���,S{�u2��^T���9,����X4�U������X�=˄V�9A9��i�go��Dw�90)�w�}���Do�h�}H��lR.�5�Ǝ'�h����2����0rX�r#_C8��fU�R�Fyo����V>B� ���|X��ƒ "+q�һg�c�M��<��|r1)�;P��X�&54�J�aߖ�����bo�5�RU�mM�(��W������B۱�۩�"udA�)N�y���v� V�z&f�xi��ώu�H��:kn��7������ړ���I��am�L�T�?'��Z�sr�f�_Pځ�c4و��!�#P���i�-��K/w�%R]�<�;�:�a\/(`��ZB�9��"~]����v>�H��Y�\0W�}�E0M̰Ǩ��4���4^ڥV�zp����,4ֺ���%����2��,]�8p'Ҫ&9)`@���P`1p���n�b<��O�8���q8)(%I�-9�J�t-UZ�5�ӌ��H�鸦� e9���Df8�ϒ�P�.i<�'هz5����TW[&�1��;��Yͮ��X�ٱ����ṥ�Jar�h�Ų�/p`�vi8�����z��<�w��	Ǯ<Y3�0_cu�5�k��N�w]Ky(�;�Eϴ�Z�B�b��j�w�.݋C|����8�W��h�T��l����R����Z� ]  }���4{��u!�
1Q����yv��`ԒhVzI\��1R����Y-�)ш�OsX^�5�vG{E���K=�������	�ni�T���.ڶ:rY��vCs��z����)�#g�ļ�/2�/�O�=4g� $�vd�֨<�x��Ghop��Hk�~l�:�5qFhќ0A3�(h��ҟDP*�kN����,��u{F8N n]�W��V��jS�i�~��a-��E	�a���Ȑѕő��T��d���?�H�}���g�"�5��Gϓ)M���F��e���[����ں���Ԓ�_v�ק�0fJ�,��h��}�&69����h�n�!C}���L��|����p�N}�\��Qj�n�aD��Z5��(Gk$����۹5'�C�me� {DI�mV�e�n�0Zr�4�)�lB)�8{��iS2%W��͜�:��u�iF�)�[���K+�[�\��W ��vq�.��t��c�Rl/"�l���B�am0�bˈ�� �����>�����٧x��N�s��d��q�e��M��>���c��n��d�J���Z�!�6w+�].�t,ݥ�2{���J�H�}A��ulI�Ĥ����OG������h�恂�=<�)x����H�>��x�>��p_ݱO���3�n � Y7�[��^�dE���X��X?2@;4g��E�[��?������BZ����Q��R16C�����3w�J��5D�U����c`�ڝr<�,����A1����ՋK���ǧ�%R���n[\����}����H,�K�<��~��	�*ɥ��N���A�.M���bD�{UK7}_�B���	^	;AW���	��~��K�$e�cGC\�-ņ�:�g� ���tM��Y�_ Ɨ��Q$ �B���hM���NӤ/N�	���r��B���k�U��[���R��mP�hӥ&��ѱ�7x�<�#�� -HM	q*��|MT������}�����arT���[�<�g.����g??��a�Q�Z��,;(�\<v��Ϭ`J�Fm{�����˒]6�0`����zj2TB��v���\��E��iF3�*�=��$٩�r7{����1v3\Sm�����<�_��W-O)����Rv @oa���#���s[��p���`�H ڡn��כRIq!C2�솪y���aY�gh}����\�k��A��."��d����C����:}J�c�\�sJ�PYv5<T�w����e�t-y�u��c��pP���Vf�.j.����ok��ഊ�������7�5]n��^�����0�xk��!oi��t�b�s*:<a�pLKi�ɷ��?[N�m �YN����<W>���T�Ѫu���>��%:$��i��2Jг��\���[�P~j���L�L�;K��w����H?�$ͯq`u��A�>w�RGs��_m<+��w���D�O�ە�5Hi�����Bz����i�>������]wXC�0�+�pCl�K4=I�%��ًi�r��x�V��a��#��E<������׏�>���~����}'�������>�~���7�W����fx��w~�g��?��f{�      �   �  x�u�]�� ��Ӌ����^f���!�o�_���Q??���}����կ��­r�ǪܪXk�jX;�ub�s�cmpk��ܚ���?��Y����i��m�4hNcMo+�1��}pú��q`�s�~@�ζ���V��+G�r� �uo���k�����fu�_ù�v�l���cx;��m�\~����H��
�;�"{�ڱ��k��㗷�+ڽNj-���5׳i�����s�h+Z��������㠸.��a ����-�{} ���P.~,����Epk�jP&)
W� L��\&�Y	X	g%��pVkz����R�J!!����Rx_9+EJQ�J�`��R�R�J�`���7��~�����!�*�Tu*��jǨ�O�����ۡA��oW~x�Tǵ`Ђ�\�_۠��g6�C�fH���e��Z0čqV�c�����&XM�j"oN�j"�L�j���&XM�jV��&XM�j"n&g5�jrV��9+����r�r�ʡ+�9�9++����rD�sVV�Y9X9g�`�U@W�Yb08�����
�*8�@V�*�*8�����
�
�*�*8�@&g��UrV	]%g�`��U�UrV	]%g��]�Y%t��U"_%g��.rV�U�8�g�C]�i�mt�j��s���i�u��M?�媛x\��
��������c�[��^�\�fyd[���������wԫm��>��_��)�      ^   �   x�U��N1Ek�.ABH,�n
�-(i�&&D�'C�E;�c8@�T��s�<���ñerL)x���F�\�E��o�A/�v�ܹMf�ѡ�m�e��ȵ��-�}�-�<$WI�r��4�B\�-�\o��%���i]�e�N�������ٶ9���g����O����dn�~�!��+W�5���W�s�>,^o%e�4y4�W���A�u�?�-U��<*N����~�      v   (  x�]�In�0E��)x!��ˠͮ�]u�ȬA��Q
�s��Xe���;q�����s��Rx$vH1�@��G�\�ۍ=M珜�9��
@=�x�L�7�$C�����pYt��J��id�!&�(��C�bBh{�����.<y�F��Pv��qBduF\-۝m;�����~.K^�F�br�q����2M���3x�ZOa�&��x_5H��S5�������.�s�'�&��u�p�L� T~
��*WC=x5t1͜��<[xN�7{P�����A8C�f�f�1??��f      n   �  x�mV���6�_���"@<cE��%GN�\�*>V$qU�{7H���l@�fz�{ �1v�D���Z�k]��L�[��xO]�/������`5�i��|�HI�2E}X�|��ķ�?��UWL���257�gӗ��D��Hq��gx��~f�����y>�mG�9
]�ð�SB��<����sU�1� "~Ã�ť	�͹�L�ݍ�qZ�Pw��jń�!����ʑwL �qxI����MI˄���?RXx�a�΄�V*�,��_B���9C�3���O�A�ZH���[r�#�P�s�:�M���X�~�8�G��2A�2Y�Q��JE^0)���z��%�	�8R�\+k�����Ж���aH9ǥPCRLj������c,!�,8hh�����`����L��w�p�
��;� I��4��ƿ�H0&�9�;Ӟ������-�>����!���Zn
��@�4�Dΰze����qe�֤�-t����c��05�!��G3(Ӭ���f)$Wڝ����(�s4d���u�1��kV{�<N��J^c��c�>'���~��2�Q��)M�=.i�i)��3��ܕx���8�'c�t&��A�%����RD����=��,�LQ-�Ŕ&�R�^y�L��v���'��}0��������g���d+D{��,���:��m�1z���2�y�'�-h��h�9\�V*��o�\Gr+\��%�5ОB_D�!��iE����B��1����t�2m��L��}a���p���On;c2'p��h ��8\�����5m&��L		;�h��X>��J2#6i��!'��
���x�P��V���G��	��s��ҹ�oMj��N̬�X��q�_K�Y���`ռ'���2c�{��񧄙2�����t��w���.�K)�`HW�Vؕ���b��i���"<m��%�����k���������r>��{f���r�b��m�2k6fD愵�����G"3
X�Q�}��L~"�j��0���4?!/�^����b�Z����d;��
л��ij�ÛJw�,�P�F��^�`�S��,�`�oz[�E�pTŜ��;�yXQ�>OP��g�Q-b������B�v\�m�i���y� nS1_�tRv�������}}{Cֹk_ӗ�	sQ�J;�[��?I�VM���8N>X�'�7���ÞW�[�K��?� ��6,�xF�-���I�p�h��_�G+���7���ML~!      `   �   x���M
�0���)� R�O�ƭ�!�hH*����s&-�
R7���7�\�H����%�g��dW���5�"�W��͐��L"2YOI�2#$sI�܌�Rr�G�FH�BbȂ|m9�4%��Ɣ�kI�A��5v�p���[��eA[�0��?md�:�����q2�q�m�0Y�C��s)l�n���؋��\��y��2���)�7�z�      �   %   x�3�t�Qp.JM�,��2�tT�I��/����� y/�      p   G   x�3����-�L�JTpI�+I��2�(���L�WHIUp�
�ss�%�$悸`	�����Ԓb�=... 8��      V   6   x�3���/�2�tL����,.)JL�/�2�H-*��K�Q@H�d��s��qqq ���      t   >  x��YYr�J���Z@)PU��0Y�%ҏ�p��?0	��5A����Kx{��0P��!)l)�N�<�d)#<��.�w<#��1i��6��}o���!����a{:��g�2��ͦz��+�u�+�(K�dE���w}�4}��'��rn��K�{�RN8��7nU�s.��2������m�=w/����y���&�LU	�������s����cUr+EeJE��C�ޥ��_�K�&;�۵9$���'�����d�X��uEuxUz��;�Hy:�ۤݷ��x���tn���h��'��⍌�$3i��t��K��"�ў�9����l�n��^�ʥV���|�%��s��x �P��/վ�y�70����pO���ɻ�����JHi�ҚQ1�@�1I���J�������N���tmri��k����6H��� �[��n���N��P4�wx'L%/�y�{���ɱ�-����]���l�O��E���8GG4(���s����d�}*��B���6��U���ɬ�LR5	���O�����d���K���'�<)�W����e�j�+�����%�@	�^$�u{9�����be0�������Jhi��#��]
�����D����ߗSm��"� ^j����okǴ)]U��N�
)�yD�P��i���ON�csn����_#�������������h��;� �˹�v��\�
X�HJ8���ag��}b�ʍɍ�l$�jc�������rh����M5�Ҫ�i�*��xJ�য়���'������}�����*�>|\M�R���51���h-��>Y£�h�+Rv�|�^��(Qk|=�����z�r���05�;��o��f{:�6�=�¿E��?��K2��Tm�j��s�k)e���<ѐ���$���]<�:z'�f��6k �i���4�FI����!�#�'���|�|���.�/��N&܆vy�V�o��R)劌2=�"<۝ ����l_�Kw�v�+Z�݁&�D�@pܦ���GauYS)���������!����ˀ�˥�����s>�{]��թ�)��'�����K Q@���U@�� �P<��x��t�xMy:d��	F8�+�-`�38�&x��-_>��S��e:�(g�!�ٗ��M�g*�QB�r��+ֹ�-����o�s�u2�ޘ<��CwOLz�C�e�BΘHkL:m)�ov��'�r�#\8`Ĝ����qB��&-ˍ��`�g�I+0N���s��¤G9��S���18�2.�Z)��4j`�~��3����:��,P����?�p�L)�<�����{�����p��}R�/�M�o&i ��Y�PΔ9��[��`F�?A�[?�>{Xm�WYrb{~���Z��#kD����0̃Ӯ;%M�r=�Q�q�Lښ��|�8�@�|�o[�sC���1"�q�`M���0u�e9�`��Tȏ�3ҭ�x�^��b�<��}X>|^�dZ�yAŨX�?�8Td�k�@���ymD����YaȤ�K+	�B�x�׭����G��c~F\���՞1�M�#y�u)TUR!�4ڿ%&�g��%K��B���li)���M�P�| <J�'��66�T�j]S!牠"i��+Rhj�
P~\?A�2^�H�C�@{rS�g-�6���eL8~E�DE�9�4��������r3�~��Ah0�`9�"�����a���6-1���gf�������En=E�&es�օ.kn+G�YO@�4г�
`��b^(�v�����rU!���:��hv�&DH�������s���/ \AC0���%����@�A�Lr<
��%A�ś�a�4�f4���"�#��鼅7l�#V�ܷ��ྥʔ�T)D� �W�$M~X��g5������zi.-1*`�/nU�sKWղ2��4�T���{�/B~��&�\�i�f�J	R:�gеޥś��F���2�e*e��BM�alb�ddi�[,T:�-Y�2aP�y^���X [��7a&<�խJ����K��*�٨�u�OaN.�U�U��^=�:@N�'W�G,��.�Zj#����< e�����g�����j��9e�m�B%����e��,'��(�ۡ�����zy����3(ƭK��rdN�GÛ��w?�q�,���Lj\Q�T2*��aH�G�s�,�`qO����R')����B�������L�p%-��KNޠf�tR��M7�qD��>���%�j*��7<dN�n74��#�X���W�B�0�a�ԓ,~�m�^�����qq#Ǳf����ͤ��(×x"�U{��'&�R6�[*g��$��]wir"U@�8WR��r
T�sKXgRh�����<n(C7�*�������ds�(D�ӻ�s��X���y�婣���ac:� ���󛻋��>���X�2-�JLl���;���jܠ=�����1����1��u�E��Iu��t��`��j�ܮݷ�*�ZW�`��J�V��k9����yu�@�I�����'R�wnMՍ�5$�3,�޷� l���qs�沄8W�=
b&vO�fIo�L����%�46M�-P뙃1���83j*8�,ލ����"�Hz԰�S�u"���Nt��� "�U�^�V��I�J��7K�xt
��m��b*9aiz{����9Whͦ�fx�;�ԋ(:�nW�x�`Q��V֙f8ճ�@c��Kߏ3H��!W��ED�����s�qy!�����'R��~G@����������J�����gE�[�4�=�Tp�k�,u]�X\�#�������z�$<V�K��{�Ң��J*�o����} �[�������P��\9�f�JX_��L��x���/���o�*%DV�M5���ya�/�Ӻ:\d�Q7\!<�{[#�;�	($���(���f[�W�x�zE��b?��S<���)��̙�f>�|8C���#<U�	�����έq�U�����"q��k�-e���vDFho�+�z*��T���?bJ:�����uT���o�����oB.�δ)�����|�
��_�$�Gڧ�5��E��A1����JL ix����=
$F^R3*\�)id���o�#n����5���H҇�oX���01��ٯR�5�sguJ͈o�Kՠ_�}Z�5v����6� �W���,xƨ�SX��$!ܮ1[A�G4����c1�'�D�ذG0fx�Dn�M����w�C��?��L��)W�Բ�I���w18�]��ōD��g��њ�Q�
oj�bh(���܅Y?}RBذR��4�,C���?��8��5͡xg3�3�c�|��جd��vdW��u<T�cTN��6��(2�Q+�k2���I�-� U�/v~8o�����'U�K]U�Ԫ)$&~{=���P��"\iE���'%�\��7�y�,|o��\	 K�HE� ��������aA�O�:xǾ�xq�e��A���fXd��wcp�b����o�!�2�g5����1�>3 �x��=6zX��X��0Y-j!���Y�y K�����o��P 6�A<Ub��@��3<��s��R��ȸK�_��[��c燯����R0�8��=�����      X      x��Z�r�<��F��Uӗ��$q�}�w����h��D*\�8o��0/6�)���ꪮ�w�;
��[h�U|:���٬:�j���f�ƋfpW['�~�2O����	����Atʯ�(��� 
"?�jd���*tֺ�^�i�����	~㬟\}��?X�����EŴ=[�G�2K�k�n�2�łK�Uo��DY�b��_K�Ϣ0��3����1v]f�W�����-�8e°tm��I�0tQ1<�c�9H3?���j��Y�_.>6�h9�p����D��S���8H�0˘�u�M����<`�g���=���z���\g��s�s����Mv3�/��X�R�?���q$�$t�"��k?	�� :�+�g����)�k���´�#t.��*k4�;؎��PYL�Ap�-��g�2�t+�p]�G�����ת�8U7�b��{��A5H��v��48fA��\������e�Mc�U�n���G'kQ����-�6���?��^PUf:ܬX�k�S|��jG���Q���������.��3c�G��u���l�G�_�M����Q[����cW<�4Y3O��0˓�-H��ܲ8��j��eHY�Vپ3ҽAk�c���O���Ěq�aJv��X��f2\������z����$�V�A�-���&#��:ӥp;뵽�))2,6{��\5����E�醶��0L��Q�B�݊�Ó�į�*#�jyF�����1��-�-˜��쀳=�d�����C�����t�v�Ve��m{�A (�U��Fg|��c��S �,N����l�y���l�4q���O�6���A�um�BleN�.���-��1�pD�NaT�O�-L�at�^�s~�k�<��sy�F�����ܵ�fO����ɏ�it�O��ދ& F+����,�u* @ξ���OS�z�_Q!A��Eg �>84���nD}�֏�K�w
o|.n��f�Տ2� 60]��o��˓<}6Z��&]a-f3k�Q;�c�]}��8���ϐ0�ձGR�qxEC�ү7t�ʫ�8
�5�8�e�5&#�:L���K���C�\��в_4�Lh�8	�rA��S�L�dT(9�L��&e��Fx��L��?�d/>p\T����K @J��i#Y�T���^��L�Y��d1���s��ϭ����m��M��P�GT�~DvkU,���'F�C8 ����&�%1R��*�UX����`��]�cF0�h�<�7�:�R����%�$���0o��=�-m����d�ض	jq\�MU�I~E��g��b��P�z�a4��b;��� �`�\|��ԝE�4M���(���xٶ�萴dmB�XMq~�Pb
֞�[�Ek��i3jo��܂%]�¹ah�L��DMT� )�^.B`L���V 2��T��Ӗe��kw�R����A-Ф.����e��&�����ʚ�t������[��Y �>����Tg�A�q׃�����u�ҿ���5��M�5uWb������l��+������v�JE�8��曮�և=}�T��!� �;3���L'��D�kuj Y���y��+Y��\j��N-�ZQC�� ��?����˖U�5/~mr��&��V(��G�C�	���2(�މ#�<\��hS��a����Hf�
��6^� X�T��<�MǪ8�m�ǯJ%ZK���s��,g d����t�{��S@��Y# C���_�؎Vt L�N�"��h�ǒ�P��&���ֻ��&{�W��2@5�  �s{��C�*��LHk��Be9����y�BH�[D5H��ܤ����|C�C�[���Z˺�k*�L����<����g�c^��Y����`w�I���>�:�V��dz���ǀ������x��b� f���3���&RVGc����@�ٖ�6�ݧJ$_{�u�6ko���ٷ��
'��V�'�B�:pM�N�B[$�u����]{	�BUh�_��e��l;��V�ť�yn��∴@c��3l&���p�A6`%�j>��I���1����J��E_]�a��g],q��2m���<�F������@�f�I����7���k4-�3U4�岁Dh�p
���AiR��吆W��;�f���x��ywj��錏[
?Zb�#�C��
�'N^
�Y�7�5F�d!<c�>O�3�T�P�GC*���n��CW�ʳd;�̡��H(��$�Y�����By��`�n%m"�e�ֈh�L�CO=�ts�\�˶R`���Q�� ��Ѭp �)L��!�И�HV���w�I�q���l7�;��ٵ�;%A�����V��{�f�� ���B� ��� 
�U����qj�/7$AN�BV�->��y���ĪO�
�i�0�=A�3`�4�%�������<�g�h>�\j*ց�vf��~P�8<������ǿ��0��%ie��S��M�:�Mz�V���@��T�5Եl�n�n{���R#6��% m�nd�<Ի��TmE��r1W�� ���w-R�ٰ��a9�/��}����N �:.|�i�/L�������(z��O�n�2E���y����zc(��z�uj�8h����ZA��3����
^���t(��3�;�T/�a.AAY��oz�z���;�H�(D�[���C#�X61,Z (8����uY#�&Zi��c�v/��Yr{�n��RJ�c3���'�$8��;-�-��D)KL��g�r�R�=Yq$�+j]�;돖�w8,�A]͏`�{]�(\9�Hh�n����]���L�s���*ǖ��a�}P'U:[ABA&����P[r`�p+^q-��U�~p���/��$+�*����7]��"87Jr Dߡ�NAR��������8V�3A���^NzZ����	�6����6�j���(
P�O��T(m�
�B*
�V��}��Y�z}���C'I@R�p�ۻ���uU�q�L0��;*&�1�^�y-m,a@��a8aH/&SWj����'&��T ،-�s���mo��oN㍏7�@��P©@��>��ԏ$����Z���MU��G��BW�d9�h����D�a�C�Ae�\:a��	4l��\��#��-&g7��D���hj������MS}�W��]�`��@��;��Uc',( �3.�� ��8���{������<�ל鹋�9C�!Խ�z{Op �g��Y�ZKa	Mq�I6}uȅL���J���ag��؜M��y8��J�Kw���BĴ�
�vD��+�����ya������Y�CQ������8"��tY�9��6�r!~G`]�J�!�O~�����:!-@�4|��j:b=�xmu<n��ɿ�-e��I|�&=b�s�yQ[ ����厽%��Qp�?�i�|ES'M~Ct_�VL�4`1* F�xd��h�\�����Mh�v	�@�����Y��5�kR�%s��i6>�|0��J	��s�p����A\�� �a(�sJ-��0	h��]9 +� �b��J��˦�U�͎��4�*g|�B�J_#Sg���/~L~�Fv��L���Î��W[��:`�y�˧�N��P���r�!G���!<�lJP��>�@���Cv�u��{����v�xY�N`]|6���*�4=���uK�cHI�sk�t݉Zd��^���ߨ*���+؛�2!j>E��h���X��`���l�Z*�Z��B�I�$O&��Xow3l���`��q�y��|+����Hrq��97 {�M3��W��֏��X �Zv���L��F}>$xx�B�ay�P�R�#�@^�8����Bmʻ��窲�bn���lnԼ ����P�)s�{�,�3mTS�<���B� �� �,V,F���³����Q� i�d��Y;:M����,9��,W�6OTL����U���r!��\��l8ݙ�����?|��Q��m�D�瑴���u�h*B�r��𩅈� �.��D�M����u���.j�eL�֡��� ����G�rm�phX�\ň�ߐ8J�\� �  �vfu�o�cs?W
�5Y#?���Q
G��$�aAb9rRW�J�yms�
S[4�
M��6j�Z:ޢ�sw#�]��L	�5��x��NV���t#�@�K/NX���C�$R����sӪ�'�n������{��[�!�𡄿���@�4���y�W����zK���\tՉ��ِ`�
�A�l�ym��jY����܀��v�k!P{(G9:{�׼��rlڝ��خ�8:��Ӎ�X�s��u�iDi�su��P�p�RV<��mGmnMFsc�P�-�`L�骘�/@V���GD��.�jV�Q�&Xi)���&�����1_�w���3)��;��ق���A���u-W�RH=��9�65�ؾ�rL�.�Y�Gŝz3�2r���#����
����@ܵtvK�+V(�S���N��ݾˍ�rmm����N#��yJ�ᘨ-�֚�����bȼKSw��Q\�@�Xb�E���h�T��l��`�����2g���y�Hw-d��Y������8]����d���v�uz}�0�s��۾���91�gi#y�X}���`P�	yy�H�W`�$>��B6:̄9ج��H����m	(a!���2���,�����to���C>�(��V��$%ѳ���r����	���3f�bK'C�ӽ��EK��?���.�Ito��:��Q{���]�]N���ǡ���;T_�m�ECAx���j��D�k�R��W�������@��� �nsitԋ:hC��f���=�2���E��K��'市RS�K
����lw���Zt.a��ʻ\ێc��b�/l%hZ圚��i�����A���m�hMGzk�f�c���1)v9��u�{P�RҦ�:.�*�ʗ.�P+���4}T�X���p���^���1��"G��m�"'�7�+���n�2�`J*.�����̔��.�P�ޗ���0��� �t�jڶɔ��2>q���c����K)Q���r<����U�$7 �8)2�paږ�y\�=[�q8�mp&)�d��Jx�G���b2_�m-��V>N��9௅MsmYX�R��PE�
j%UP'��l.o��qy$�edrc�p�� \���u-���~{�e.2�5&ρ���*�v���=!ڝ��u]*��#X����2��fB��4�ӵ}�^^��T��Rv���Vwr��ʹ��7�/���I�Uq<�.洤�LN��zq�F��Z��\���[!�۾�Z�K8ŋk����qch��-ϔ�R<2������:֔�C�\�<}����}���.]��<��.��[�b��qn�^	Եǝ5�c�R5��5�X�l<獶�D�+�xp����0I�08���'<�r�1ݮ�n���\*�)Z�����շ9��a��.�z�]r����j@PC[�_�h����~�1��a@��b�'��_���O�/Ӳ-��ڹ��2���������?�y��<��i��ˏmr_�ƃ���a�>��i�gr�v��)���?������#�?��=��v����j�vN��K��旟����^����8Iך�:��i���_�c -:���W(�!��W��7���UF��4㹜s������N�ߧ�ɯӯ��g��V���F���߷�~_�v���~���jD�Y���������}ΟS��1�Sq\��M���$&�]n��,�;�1��cq߿��?r��������hup�ܣ��k�������lC�1x�R���������k�_���zoݓ�eTA�������bH��t�住�ɽ=<V��/{��G�DQ�o�A�q�4���Q�m�-��9���E���bf����5P��t"vi�����n��o�����Z=�~�d�[o���~�~l߆3�-�������F�����H�}(�n�!$|�\zˢ��q@D���/�H���Y����� �8$�      �   �   x��α�0���0MZ�����D��XNiI	�������'�����쇨�XN7����+��i�����P�s>��Fk��}��}rN�[��?�����}0��;��x���&�|P	�7��(��4 �O3��     