USE [TFP_PRD]
GO
/****** Object:  StoredProcedure [dbo].[PROC_DESATIVA_PARCEIRO_TFP]    Script Date: 26/12/2016 16:03:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Jefferson do Nascimento
-- Create date: 29/11/2016
-- Description:	Na fila D RETORNO DISTRATO/ADITIVO e D RETORNO NOTIFICAÇÃO, inserimos uma data de assinatura, 
--				que corresponde à data em que o parceiro recebeu o documento de descredenciamento.
--				Esta data de assinatura será o start para corte de login no TimForma Plus.
--				A partir de 65 dias desta data, o acesso do parceiro no TFP deve ficar inativo.

-- =============================================
ALTER PROCEDURE [dbo].[PROC_DESATIVA_PARCEIRO_TFP] 

AS
BEGIN

		DECLARE @assunto VARCHAR(200)
		DECLARE @corpo VARCHAR(1000)

		DECLARE @cancel_logins_dt_assinatura VARCHAR(100)
		DECLARE @id_matriz_parceiro int
		DECLARE @nom_razao_social VARCHAR(500)
		DECLARE @cnpj_parceiro VARCHAR(50)
		DECLARE @cod_bscs VARCHAR(50) 
		DECLARE @login VARCHAR(50) 
		DECLARE @cod_usuario INT

		DECLARE CursorGeral CURSOR FOR

		        -- Seleciona todos os parceiros que atendem  a data de expiração
				Select  distinct TB.cancel_logins_dt_assinatura, TB.id_matriz_parceiro, GP.nom_razao_social,
								 GP.cnpj_parceiro, GP.cod_bscs, AU.login, AU.cod_usuario
				from cadtim.dbo.tb_solicitacao  TB
				inner join GDC_PARCEIRO GP on GP.cod_parceiro = TB.id_matriz_parceiro 
				inner join ADM_USUARIO AU on AU.login =  GP.login
				where cancel_logins_dt_assinatura is not null
				and cancel_logins_dt_assinatura < getdate()-65
				and AU.cod_cargo = 27				-- Cargo de parceiro
				and GP.cod_status_parceiro <> 1		-- Credenciado ativo
				and AU.sit_login_liberado = 1	

	OPEN CursorGeral

		FETCH NEXT FROM CursorGeral INTO @cancel_logins_dt_assinatura, @id_matriz_parceiro, @nom_razao_social, @cnpj_parceiro, @cod_bscs, @login, @cod_usuario

		-- Percorrendo linhas do cursor (enquanto houverem)
		WHILE @@FETCH_STATUS = 0
		BEGIN

			SET @assunto = 'Processo de desativação de login automático - TFP';
			SET @corpo = 'Prezado(a),<br><br>Informamos que foi desativado o login <strong>' + @login + 
			             '<br><br></strong> Razão Social: <strong>' + @nom_razao_social + 
						 '<br></strong><br>CNPJ Parceiro: <strong>' + @cnpj_parceiro + '</strong> ' +
						 '<br></strong><br>CustCode: <strong>' + @cod_bscs + '</strong> ' +
						 '<br></strong><br>Data de Assinatura: <strong>' + @cancel_logins_dt_assinatura + '</strong> ';
			
			EXEC PROC_GDC_ENVIA_EMAIL 'descredenciamento_nacional@timbrasil.com.br', @assunto, @corpo, null, null, null
			
			update ADM_USUARIO set sit_login_liberado = 0, dt_bloqueio_acesso = getdate() where cod_usuario = @cod_usuario	-- Desativar acesso ao TFP
			
			insert into adm_auditoria_sistema (cod_usuario, dt_auditoria, descricao) 
			values (@cod_usuario, GETDATE(), 'BLOQUEADO APÓS 65 DIAS DA DATA DE DESCREDENCIAMENTO.')	-- Gravar log para auditoria

			-- Lendo a próxima linha
			FETCH NEXT FROM CursorGeral INTO @cancel_logins_dt_assinatura, @id_matriz_parceiro, @nom_razao_social, @cnpj_parceiro, @cod_bscs, @login, @cod_usuario
		END

		-- Fechando Cursor para leitura
		CLOSE CursorGeral

		-- Desalocando o cursor
		DEALLOCATE CursorGeral 

END


--EXECUTE PROC_DESATIVA_PARCEIRO_TFP
