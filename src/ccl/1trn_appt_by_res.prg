/*************************************************************************
 
        Script Name:    1trn_appt_by_res.prg
 
        Description:    Clinical Office - MPage Developer
                        Appointment by Resource Training CCL Script
 
        Date Written:   December 4, 2025
        Written by:     John Simpson
                        Precision Healthcare Solutions
 
 *************************************************************************
            Copyright (c) 2025 Precision Healthcare Solutions
 
 NO PART OF THIS CODE MAY BE COPIED, MODIFIED OR DISTRIBUTED WITHOUT
 PRIOR WRITTEN CONSENT OF PRECISION HEALTHCARE SOLUTIONS EXECUTIVE
 LEADERSHIP TEAM.
 
 FOR LICENSING TERMS PLEASE VISIT www.clinicaloffice.com/mpage/license
 
 *************************************************************************
                            Special Instructions
 *************************************************************************
 Called from 1co5_mpage_entry. Do not attempt to run stand alone. If you
 wish to test the development of your custom script from the CCL back-end,
 please run with 1co_mpage_test.
 
 Possible Payload values:
 
    "customScript": {
        "script": [
            "name": "your custom script name:GROUP1",
            "id": "identifier for your output, omit if you won't be returning data",
            "run": "pre or post",
            "parameters": {
                "your custom parameters for your job"
            }
        ]
    }
 
 *************************************************************************
                            Revision Information
 *************************************************************************
 Rev    Date     By             Comments
 ------ -------- -------------- ------------------------------------------
 001    12/04/25 J. Simpson     Initial Development
 *************************************************************************/
drop program 1trn_appt_by_res:group1 go
create program 1trn_appt_by_res:group1

prompt 
	"Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to. 

with OUTDEV

 
/*
	The parameters for your script are stored in the PAYLOAD record structure. This
	structure contains the entire payload for the current CCL execution so parameters
	for other Clinical Office jobs may be present (e.g. person, encounter, etc.).
 
	Your payload parameters are stored in payload->customscript->script[script number].parameters.
 
	The script number for your script has been assigned to a variable called nSCRIPT.
 
	For example, if you had a parameter called fromDate in your custom parameters for your script
	you would access it as follows:
 
	set dFromDate = payload->customscript->script[nscript]->parameters.fromdate
 
	**** NOTE ****
	If you plan on running multiple pre/post scripts in the same payload, please ensure that
	you do not have the same parameter with different data types between jobs. For example, if
	you ran two pre/post jobs at the same time with a parameter called fromDate and in one job
	you passed a valid JavaScript date such as  "fromDate": "2018-05-07T14:44:51.000+00:00" and
	in the other job you passed "fromDate": "05-07-2018" the second instance of the parameter
	would cause an error.
*/
  
; This is the point where you would add your custom CCL code to collect data. If you did not
; choose to clear the patient source, you will have the encounter/person data passed from the
; mpage available for use in the PATIENT_SOURCE record structure.
;
; There are two branches you can use, either VISITS or PATIENTS. The format of the
; record structure is:
;
; 1 patient_source
;	2 visits[*]
;		3 person_id			= f8
;		3 encntr_id			= f8
;	2 patients[*]
;		3 person_id			= f8
;
; Additionally, you can alter the contents of the PATIENT_SOURCE structure to allow encounter
; or person records to be available for standard Clinical Office scripts. For example, your custom
; script may collect a list of visits you wish to have populated in your mPage. Instead of
; manually collecting your demographic information, simply add your person_id/encntr_id combinations
; to the PATIENT_SOURCE record structure and ensure that the standard Clinical Office components
; are being called within your payload. (If this is a little unclear, please see the full
; documentation on http://www.clinicaloffice.com).
 
; ------------------------------------------------------------------------------------------------
;								BEGIN YOUR CUSTOM CODE HERE
; ------------------------------------------------------------------------------------------------
 
; Define the custom record structure you wish to have sent back in the JSON to the MPage. The name
; of the record structure can be anything you want but you must make sure it matches the structure
; name used in the add_custom_output subroutine at the bottom of this script.

; Allow running from DA2/Reporting Portal
if (validate(patient_source) = 0)
    execute 1co5_mpage_redirect:group1 ^MINE^,^organizer-appointments-by-resource^
    go to end_program
endif


free record rCustom
record rCustom (
	1 error                    = vc
)

call echorecord(payload->customscript->script[nscript]->parameters)

; Execute each action
case(payload->customscript->script[nscript]->parameters.action)
    of "load-table": call loadTable(null)
    of "load-event": call loadEvent(payload->customscript->script[nscript]->parameters.schEventId)
endcase

; Load the appointment table data
subroutine loadTable(null)

    free record rCustom
    record rCustom (
    	1 data[*]
	       2 person_id             = f8
	       2 encntr_id             = f8
    	   2 sch_event_id          = f8
	       2 resource_cd           = f8
	       2 resource              = vc
    	   2 patient_name          = vc
	       2 mrn                   = vc
    	   2 fin                   = vc
	       2 appointment_dt_tm     = dq8
	       2 appointment_type      = vc
    	   2 appointment_location  = vc
	       2 appointment_state     = vc	   
    ) with persistscript
    
    ; Collect code values
    declare cv4_MRN = f8 with noconstant(uar_get_code_by("MEANING", 4, "MRN"))
    declare cv319_FIN = f8 with noconstant(uar_get_code_by("MEANING", 319, "FIN NBR"))

    ; Collect appointment table data
    select into "nl:"
        resource            = uar_get_code_display(sa.resource_cd),
        sort_date           = format(sa.beg_dt_tm, "yyyymmddhhmm;;q")
    from    sch_appt            sa,
            sch_event           se,
            sch_appt            sa2,
            person              p,
            person_alias        pa,
            encntr_alias        ea
    plan sa
        where sa.beg_dt_tm between cnvtdatetime(payload->customscript->script[nscript]->parameters.fromdate)
                               and cnvtdatetime(concat(payload->customscript->script[nscript]->parameters.toDate, " 23:59:59"))
        and expand(nNum, 1, size(payload->customscript->script[nscript]->parameters.resourcecd, 5), sa.resource_cd,
                        payload->customscript->script[nscript]->parameters.resourcecd[nNum])
        and sa.state_meaning in ("SCHEDULED", "CHECKED IN", "CHECKED OUT", "CONFIRMED")                        
        and sa.version_dt_tm > sysdate
        and sa.active_ind = 1
        and sa.end_effective_dt_tm > sysdate
    join se
        where se.sch_event_id = sa.sch_event_id
        and se.version_dt_tm > sysdate
        and se.active_ind = 1
        and se.end_effective_dt_tm > sysdate
    join sa2
        where sa2.sch_event_id = se.sch_event_id
        and sa2.role_meaning = "PATIENT"
        and sa2.state_meaning in ("SCHEDULED", "CHECKED IN", "CHECKED OUT", "CONFIRMED")
        and sa2.version_dt_tm > sysdate
        and sa2.active_ind = 1
        and sa2.end_effective_dt_tm > sysdate
    join p
        where p.person_id = sa2.person_id
    join pa
        where pa.person_id = p.person_id
        and pa.person_alias_type_cd = cv4_MRN
        and pa.active_ind = 1
        and pa.end_effective_dt_tm > sysdate
    join ea
        where ea.encntr_id = sa2.encntr_id
        and ea.encntr_alias_type_cd = cv319_FIN
        and ea.active_ind = 1
        and ea.end_effective_dt_tm > sysdate
    order resource, sort_date
    head report
        nCount = 0
    detail
        nCount = nCount + 1
        stat = alterlist(rCustom->data, nCount)
        rCustom->data[nCount].person_id = sa2.person_id
        rCustom->data[nCount].encntr_id = sa2.encntr_id
        rCustom->data[nCount].sch_event_id = se.sch_event_id
        rCustom->data[nCount].resource_cd = sa.resource_cd
        rCustom->data[nCount].resource = uar_get_code_display(sa.resource_cd)
        rCustom->data[nCount].patient_name = p.name_full_formatted
        rCustom->data[nCount].mrn = cnvtalias(pa.alias, pa.alias_pool_cd)
        rCustom->data[nCount].fin = cnvtalias(ea.alias, ea.alias_pool_cd)
        rCustom->data[nCount].appointment_dt_tm = sa.beg_dt_tm
        rCustom->data[nCount].appointment_type = uar_get_code_display(se.appt_type_cd)
        rCustom->data[nCount].appointment_location = uar_get_code_display(sa2.appt_location_cd)
        rCustom->data[nCount].appointment_state = uar_get_code_display(sa2.sch_state_cd)
    with expand=1
end

; Load the resources, details and orders for a specific sch_event_id
subroutine loadEvent(nSchEventId)

    free record rCustom
    record rCustom (
    	1 resources[*]
            2 role                  = vc
            2 resource              = vc
            2 state                 = vc
            2 role_description      = vc
        1 details[*]
            2 description           = vc
            2 value                 = vc
        1 orders[*]
            2 orderable             = vc
            2 order_status          = vc
            2 details               = vc          
    ) with persistscript
    
    ; Collect the resources
    select into "nl:"
        role_seq            = sa.role_seq
    from    sch_appt                sa
    plan sa
        where sa.sch_event_id = nSchEventId
        and sa.role_meaning != "PATIENT"
        and sa.state_meaning in ("SCHEDULED", "CHECKED IN", "CHECKED OUT", "CONFIRMED")                        
        and sa.version_dt_tm > sysdate
        and sa.active_ind = 1
        and sa.end_effective_dt_tm > sysdate
    order role_seq
    head report
        nCount = 0
    detail
        nCount = nCount + 1
        stat = alterlist(rCustom->resources, nCount)
        rCustom->resources[nCount].role = uar_get_code_display(sa.sch_role_cd)
        rCustom->resources[nCount].resource = uar_get_code_display(sa.resource_cd)
        rCustom->resources[nCount].state = uar_get_code_display(sa.sch_state_cd)
        rCustom->resources[nCount].role_description = sa.role_description
    with counter
    
    ; Collect the appointment details
    select into "nl:"
        description         = uar_get_code_display(sed.oe_field_id),
        seq_nbr             = sed.seq_nbr
    from    sch_event_detail        sed
    plan sed
        where sed.sch_event_id = nSchEventId
        and sed.version_dt_tm > sysdate
        and sed.active_ind = 1
        and sed.end_effective_dt_tm > sysdate
    order description, seq_nbr        
    head report
        nCount = 0
    detail
        nCount = nCount + 1
        stat = alterlist(rCustom->details, nCount)
        rCustom->details[nCount].description = description
        rCustom->details[nCount].value = sed.oe_field_display_value
    with counter
    
    ; Collect the attached orders
    select into "nl:"
        beg_schedule_seq            = sea.beg_schedule_seq
    from    sch_event_attach        sea,
            orders                  o
    plan sea
        where sea.sch_event_id = nSchEventId
        and sea.attach_type_meaning = "ORDER"
        and sea.version_dt_tm > sysdate
        and sea.active_ind = 1
        and sea.end_effective_dt_tm > sysdate
    join o
        where o.order_id = sea.order_id
    order
        beg_schedule_seq
    head report
        nCount = 0
    detail
        nCount = nCount + 1
        stat = alterlist(rCustom->orders, nCount)  
        rCustom->orders[nCount].orderable = uar_get_code_display(o.catalog_cd)
        rCustom->orders[nCount].order_status = uar_get_code_display(o.order_status_cd)
        rCustom->orders[nCount].details = o.order_detail_display_line
    with counter
end
 
; ------------------------------------------------------------------------------------------------
;								END OF YOUR CUSTOM CODE
; ------------------------------------------------------------------------------------------------
 
; If you wish to return output back to the MPage, you need to run the ADD_CUSTOM_OUTPUT function.
; Any valid JSON format is acceptable including the CNVTRECTOJSON function. If using
; CNVTRECTOJSON be sure to use parameters 4 and 1 as shown below.
; If you plan on creating your own JSON string rather than converting a record structure, be
; sure to have it in the format of {"name":{your custom json data}} as the ADD_CUSTOM_OUTPUT
; subroutine will extract the first sub-object from the JSON. (e.g. {"name":{"personId":123}} will
; be sent to the output stream as {"personId": 123}.

#skip_logic

call add_custom_output(cnvtrectojson(rCustom, 4, 1))
 
#end_program
 
end go