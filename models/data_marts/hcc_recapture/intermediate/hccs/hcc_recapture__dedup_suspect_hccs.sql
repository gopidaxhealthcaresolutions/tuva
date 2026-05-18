{{ config(
     enabled = var('claims_enabled', False) | as_bool
   )
}}

with base as (
    select
        person_id
        , payer
        , data_source
        , {{ date_part('year', 'recorded_date') }} as collection_year
        , recorded_date
        , model_version
        , claim_id
        , hcc_code
        , hcc_description
        , suspect_hcc_flag
        , eligible_claim_flag
        , hcc_type
        , hcc_source
    from {{ ref('hcc_recapture__int_suspect_hccs')}}
)

, add_rank as (
    select 
        * 
    -- Ensure only 1 hcc type per HCC
    , rank() over (
        partition by person_id, payer, claim_id, hcc_code, model_version, collection_year
            order by case 
                        when hcc_type = 'captured' then 1
                        when hcc_type = 'suspect' then 2
                     end
    ) as hcc_type_rank      
    from base  
)

select 
    * 
from base
where hcc_type_rank = 1

