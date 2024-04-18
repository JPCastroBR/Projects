SELECT
    PM.DT_PRE_MED,
    ATE.CD_ATENDIMENTO,
    PAC.DT_NASCIMENTO,
    CASE
        WHEN DBAMV.FN_IDADE(PAC.DT_NASCIMENTO) > 60 THEN 'IDOSO'
        WHEN DBAMV.FN_IDADE(PAC.DT_NASCIMENTO) < 16 THEN 'CRIANCA'
        ELSE 'ADULTO'
    END FAIXA_ETARIA,    
    DBAMV.FN_IDADE(PAC.DT_NASCIMENTO) IDADE,
    PAC.TP_SEXO,
    TA.CD_TIPO_INTERNACAO,
    TA.DS_TIPO_INTERNACAO,
    SE.CD_SERVICO,
    SE.DS_SERVICO,
    TP.DS_TIP_PRESC
from
    PRE_MED PM 
    INNER JOIN ITPRE_MED IPM        ON PM.CD_PRE_MED=IPM.CD_PRE_MED AND IPM.CD_TIP_ESQ = 'DEV'
    INNER JOIN TIP_PRESC TP         ON IPM.CD_TIP_PRESC=TP.CD_TIP_PRESC 
    INNER JOIN ATENDIME ATE         ON ATE.CD_ATENDIMENTO=PM.CD_ATENDIMENTO
    INNER JOIN PACIENTE PAC         ON ATE.CD_PACIENTE=PAC.CD_PACIENTE
    INNER JOIN TIPO_INTERNACAO TA   ON TA.CD_TIPO_INTERNACAO = ATE.CD_TIPO_INTERNACAO
    INNER JOIN SERVICO SE           ON SE.CD_SERVICO=ATE.CD_SERVICO
WHERE 
    PM.DT_PRE_MED BETWEEN '01/01/2024' AND '30/01/2024'
    AND PM.CD_PRE_MED IN ( --SELECIONA AS PRIMEIRAS PRESCRICOES COM DEV DE CADA ATENDIMENTO
                            select
                                min(pm1.CD_PRE_MED)
                            from 
                                dbamv.itpre_med ipm1
                                inner join pre_med pm1 on pm1.cd_pre_med=ipm1.CD_PRE_MED
                            where
                                ipm1.CD_TIP_ESQ = 'DEV'
                            group by pm1.cd_atendimento
                        )
;