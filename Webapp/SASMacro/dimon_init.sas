/* ========================================================================= */
/* Program : dimon_init.sas                                                  */
/* Purpose : initialization for DI Monitor Stored Processes                  */
/*                                                                           */
/* Do NOT modify this file.  Any additions or changes should be made in      */
/* dimon_usermods.sas.                                                       */
/*                                                                           */
/* Change History                                                            */
/* Date    By     Changes                                                    */
/* 01jun10 eombah initial version                                            */
/* 30aug12 eombah added macvars jsroot and cssroot                           */
/* 19nov16 eombah updated for v3                                             */
/* ========================================================================= */
%macro dimon_init;

  options nonotes nosource nosource2 nomprint;

  %let dts1 = %sysfunc(datetime());

  /* _debug parameter is passed on the url as &_debug= */
  %global _debug;
  %if (&_debug. ne 0) %then
  %do;
       options notes source source2 mprint;
       %put NOTE: setting debug options because %nrstr(&)_DEBUG = &_DEBUG.;
       options msglevel=i;
       options sastrace=',,,d' sastraceloc=saslog nostsuffix;
  %end;

  %put NOTE: ====================================================================;
  %put NOTE: dimon_init macro started execution.;

  %macro _webout;
    %if (%sysfunc(fileref(_webout)) = 0) %then
        _webout;
    %else
        print;
  %mend _webout;

  %macro create_table_or_view;
    CREATE %if (&engine = SAS) %then TABLE; %else VIEW;
  %mend create_table_or_view;

  %global urlspa sproot webroot _odsstyle viewlog_maxfilesize gantt_width trend_days
          flow_completion_mode flow_completion_mode_2_idle_time lsf_flow_finished_dir
          flow_scheduled_dts_match_seconds
          ;

  /* ------------------------------------------------------------------------- */
  /* Default settings, to be overriden by %dimon_usermods                      */
  /* Do NOT modify this file.  Any additions or changes should be made in      */
  /* dimon_usermods.sas.                                                       */
  /* ------------------------------------------------------------------------- */

  /* URL to the SAS Stored Process Web Application */
  %let urlspa               = /SASStoredProcess/do;

  /* Metadata folder where the dimon stored processes are located */
  %let sproot               = /My Company/Application Support/EOM DI Job Monitor/Stored Processes;

  /* Relative URL path where the js, css, and images components are located */
  %let webroot              = /eom/dimon;

  /* ODS style */
  %let _odsstyle            = dimon;

  /* For SAS log files beyond this filesize, you are prompted to download. This is an IE setting, for Chrome and Firefox this value is doubled */
  %let viewlog_maxfilesize  = 2097152; /* in bytes */

  /* Width of the gantt charts in pixels */
  %let gantt_width          = 150;

  /* Default numer of days to show elapsed time trend for */
  %let trend_days           = 90;

  /* Flow completion mode - When is a flow marked as completed? */
  /* 1 : when #jobs_completed = #jobs_in_flow (default) */
  /* 2 : when #jobs_completed < #jobs_in_flow and nothing has been running for &flow_completion_mode_2_idle_time. seconds */
  /* 3 : when file <flow-id> exists in the &lsf_flow_finished_dir. Subflows use mode 1 */
  /* 4 : when file <flow-id> exists in the &lsf_flow_finished_dir. Subflows use mode 2 */
  /* 5 : when file <flow-id> does not exist in the &lsf_flow_active_dir. Subflows use mode 1 */
  /* 6 : when file <flow-id> does not exist in the &lsf_flow_active_dir. Subflows use mode 2 */
  %let flow_completion_mode             = 1;
  %let flow_completion_mode_2_idle_time = 60; /* idle seconds before marking flow COMPLETED in mode 2     */
  %let lsf_flow_finished_dir            = ;   /* for modes 3 and 4 */
  %let lsf_flow_active_dir              = ;   /* for modes 5 and 6 */

  /* The maximum time between scheduled start and actual start of a flow to be matched */
  %let flow_scheduled_dts_match_seconds = 60;

  /* Include dimon_usermods */
  %dimon_usermods;

  /* Get dimon engine. When it is  something other than SAS, dimon creates SQL */
  /* views instead of tables, where applicable, to let SQL  pass through.      */
  %global engine;
  proc sql noprint;
    select case
             when engine in ('BASE','V9','REMOTE') then 'SAS'
             else engine
           end into :engine
    from   sashelp.vlibnam
    where  libname = 'DIMON'
    ;
  quit;

  %put NOTE: ENGINE                           = &engine.;
  %put NOTE: URLSPA                           = &urlspa.;
  %put NOTE: SPROOT                           = &sproot.;
  %put NOTE: WEBROOT                          = &webroot.;
  %put NOTE: _ODSSTYLE                        = &_odsstyle.;
  %put NOTE: VIEWLOG_MAXFILESIZE              = &viewlog_maxfilesize.;
  %put NOTE: GANTT_WIDTH                      = &gantt_width.;
  %put NOTE: TREND_DAYS                       = &trend_days.;
  %put NOTE: FLOW_COMPLETION_MODE             = &flow_completion_mode.;
  %put NOTE: FLOW_COMPLETION_MODE_2_IDLE_TIME = &flow_completion_mode_2_idle_time.;
  %put NOTE: LSF_FLOW_FINISHED_DIR            = &lsf_flow_finished_dir.;
  %put NOTE: FLOW_SCHEDULED_DTS_MATCH_SECONDS = &flow_scheduled_dts_match_seconds.;

  ods path WORK.TAGSETS(UPDATE) SASHELP.TMPLMST(READ);
  proc template;
    define style styles.dimon;
      parent = styles.sasweb;
        notes "DI Monitor Style";
        class body /
          fontfamily = 'Roboto,Open Sans,Verdana,Arial'
          fontsize   = 9pt
          color      = #808080
        ;
        class systemtitle /
          fontfamily = 'Roboto,Open Sans,Verdana,Arial'
          fontsize   = 9pt
          fontstyle  = roman
          color      = #0288d1
        ;
        class systemfooter /
          fontfamily = 'Roboto,Open Sans,Verdana,Arial'
          fontsize   = 9pt
          fontstyle  = roman
          color      = #0288d1
        ;
        class table /
          fontfamily  = 'Roboto,Open Sans,Verdana,Arial'
          fontsize    = 9pt
          cellspacing = 1
          cellpadding = 10
          background  = #f0f0f0
        ;
        style table from output /
          frame = void
          rules = none
        ;
        style Header from HeadersAndFooters /
          /*background = #0066cc*/
          background = #0288d1
          fontfamily = 'Roboto,Open Sans,Verdana,Arial'
          fontsize   = 9pt
        ;
        style Footer from HeadersAndFooters /
          background = #0288d1
          fontfamily = 'Roboto,Open Sans,Verdana,Arial'
          fontsize   = 9pt
        ;
        class data /
          fontfamily = 'Roboto,Open Sans,Verdana,Arial'
          fontsize   = 9pt
          color      = #404040
        ;
        class notecontent /
          fontfamily = 'Roboto,Open Sans,Verdana,Arial'
          fontsize   = 8pt
          color      = #0288d1
        ;
    end;
  run;

  %let dts2 = %sysfunc(datetime());
  %let elapsed = %sysfunc(putn(%sysevalf(&dts2. - &dts1.),8.2));
  %put NOTE: dimon_init macro completed execution in &elapsed. seconds.;
  %put NOTE: ====================================================================;

%mend dimon_init;
