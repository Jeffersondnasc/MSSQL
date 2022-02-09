USE [NOME_BD]
GO
/****** Object:  StoredProcedure [dbo].[PROC_EXECUTA_CURSOR]    Script Date: 07/02/2021 19:55:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Jefferson do Nascimento
-- Create date: 	07/02/2022


-- =============================================
ALTER PROCEDURE [dbo].[PROC_EXECUTA_CURSOR] 

AS
BEGIN

		DECLARE @DATA DATETIME,
		DECLARE @registro1 INT, 
		DECLARE @registro2 INT

		DECLARE CursorGeral CURSOR FOR

				Select TA.registro1, TB.registro2 FRom TABELA_A  TA
				inner join TABELA_B TB on TB.ID_TABELA_A = TA.ID 
				where TA.ACTIVE = 1
				and TB.DT_INICIO >= @DATA


	OPEN CursorGeral

		FETCH NEXT FROM CursorGeral INTO @registro1, @registro2

		-- Percorrendo linhas do cursor (enquanto houverem)
		WHILE @@FETCH_STATUS = 0
		BEGIN

			insert into TABELA_C (registro1, registro2) 
			values (@registro1, @registro2)

			-- Lendo a próxima linha
			FETCH NEXT FROM CursorGeral INTO @registro1, @registro2
		END

		-- Fechando Cursor para leitura
		CLOSE CursorGeral

		-- Desalocando o cursor
		DEALLOCATE CursorGeral 

END


--EXECUTE PROC_EXECUTA_CURSOR
