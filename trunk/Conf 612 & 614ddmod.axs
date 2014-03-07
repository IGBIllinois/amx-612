PROGRAM_NAME='Conf 612 & 614'
(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)
(* REV HISTORY:                                            *)
(***********************************************************)

(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE
dvAudia1 	= 5001:1:0	//Biamp Nexia CS Straight Thru Cable 38400 Baud.				
dvMatrix  	= 5001:2:0	//Extron 450
dvProj612   	= 5001:3:0	//Epson Powerlite G5750 
dvProj614Rt   	= 5001:4:0	//Proxima C450 Right side as looking at Screen
dvProj614Lt   	= 5001:5:0	//Proxima C450 Left side as looking at Screen
dvRelay	  	= 5001:8:0	//Relay for Rack Power.
dvTp614	  	= 10001:1:0   	//MVP-8400 in the room with 1 Projectors.
dvTp612	  	= 10005:1:0   	//MVP-8400 in the room with 2 Projector.


//Dvtp1a = 10001:1:0
(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT
dev dvTpBoth[] = 
{
    dvTp612,dvTp614
}

integer PowerRelay1 = 1
integer PowerRelay2 = 2
integer PowerRelay3 = 3
integer PowerRelay4 = 4

integer ProjCenter612 = 3
integer ProjRight614 = 4
integer ProjLeft614 = 5
integer Proj614comb = 6

integer nPC = 3
integer nRight = 5
integer nLeft = 6
integer nCombined = 1
integer CombineRooms = 41
INTEGER TL1 = 1
INTEGER TL2 = 2
integer OffTime = 60	//Used to count down the time to turn the system off.


integer nRgbPortBtn[]=		//For selecting the RGB floor jacks
{
    50,	//612 Right
    51,	//612 Left
    52,	//614 Right
    53	//614 Left
}
integer nRoomMode[]= 
{
    12,	//Normal Mode
    13,	//Expanded Mode.
    14	//UnCombine Rooms.
}
integer nBtnDest[] = 
{
    1,	//Left Proj 614
    2,	//Right Proj 614
    3	//Both
}
integer nBtnPwrOff[] = 
{
    4	//This is the YES button.
}
integer nBtnPodiumLoc[]=
{
    5,	//Right side of room.
    6	//Left side of room.
}
INTEGER nSrcSelects[] = 
{
    93	//Laptop
}
integer nProjAdvance[] = 
{
    99,		//Proj Power ON	612
    100,	//Proj Power Off 612
    101,	//Proj Power ON	614 Left
    102,	//Proj Power OFF 614 Left 
    103,	//Proj Power ON	614 right 
    104,	//Proj Power OFF 614 right 
    105,	//Proj Power Blank 612
    106,	//Proj Power Blank Left
    107 	//Proj Power Blank Right

}

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE
dev dvProj[] = 
{
    dvProj612,dvProj614Lt,dvProj614Rt
}


integer SystemPower
integer nCurrentSource[2]	//1st location is 612, 2nd is 614.
integer nPodiumLocation[2]
integer PowerState[2]		//Relays.
ProjPowerStatus[3]
integer RoomCombineMode
LONG TimeArray[100] 
INTEGER COUNT
INTEGER nTimeBlock
INTEGER nCheckPwr[3]
INTEGER nProjPwrStatus[3]
CenterProjstring[100]	//612 Only Projector
RightProjstring[100]	//614 right Projector
LeftProjstring[100]	//614 Left Projector

PROJ_POWER1
PROJ_POWER2
PROJ_POWER3
PROJ_BUFFER1[10]
PROJ_BUFFER2[10]
PROJ_BUFFER3[10]
DISPLAY
RUN1
RUN2
RUN3

(***********************************************************)
(*               LATCHING DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_LATCHING

(***********************************************************)
(*       MUTUALLY EXCLUSIVE DEFINITIONS GO BELOW           *)
(***********************************************************)
DEFINE_MUTUALLY_EXCLUSIVE

(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)
(* EXAMPLE: DEFINE_FUNCTION <RETURN_TYPE> <NAME> (<PARAMETERS>) *)
(* EXAMPLE: DEFINE_CALL '<NAME>' (<PARAMETERS>) *)
INCLUDE 'AMX_ArrayLib.axi'
INCLUDE 'nAMX_QUEUE.axi'
INCLUDE 'Biamp_Audia.axi'
DEFINE_CALL 'Power Relay'(integer Relay,integer nRoom)	//1 = 612 2 = 614
{
    PowerState[nRoom] = Relay
    If((PowerState[1] = 0) && (PowerState[2] = 0))
    {
	SEND_STRING 0:1:0,"'Power Relays OFF',13,10"
	OFF[dvRelay,PowerRelay1]
	OFF[dvRelay,PowerRelay2]
	OFF[dvRelay,PowerRelay3]
	OFF[dvRelay,PowerRelay4]
    }
    If((PowerState[1] = 1) || (PowerState[2] = 1))
    {
	SEND_STRING 0:1:0,"'Should have turned Power Relays ON',13,10"
	If(![dvRelay,PowerRelay1])
	{
	    SEND_STRING 0:1:0,"'Power Relays ON',13,10"
	    ON[dvRelay,PowerRelay1]
	    ON[dvRelay,PowerRelay2]
	    ON[dvRelay,PowerRelay3]
	    ON[dvRelay,PowerRelay4]
	    Wait 30
	    {
		
	    }
	}
    }
}
DEFINE_CALL 'Proj Power'(integer Proj_Num, char Proj_Control[10]) //Projector Control Sub.
{
    SELECT
    {
	ACTIVE(Proj_Num = 3):			//612_proj
	{
	    SELECT
	    {
		ACTIVE(Proj_Control = 'PON'):
		{
		    //IF(PROJ_POWER1 = 0)
		    //{
			SEND_STRING dvProj612,"'PWR ON',$0D"
			(*WAIT 25
			{
			    RUN1 = 1
			}*)
		   //}
		}
		ACTIVE(Proj_Control = 'POF'):
		{
		    //IF(PROJ_POWER1 = 1)
		    //{
			SEND_STRING dvProj612,"'PWR OFF',$0D"
			(*RUN1 = 0*)
		    //}
		}
	    }
	}
	ACTIVE(Proj_Num = 4):			//614R
	{
	    SELECT
	    {
		ACTIVE(Proj_Control = 'PON'):
		{
		    IF(PROJ_POWER2 = 0)
		    {
			SEND_STRING dvProj614Rt,'(PWR1)'
			WAIT 25
			{
			    RUN2 = 1
			}
		    }
		}
		ACTIVE(Proj_Control = 'POF'):
		{
		    IF(PROJ_POWER2 = 1)
		    {
			SEND_STRING dvProj614Rt,'(PWR0)'
			RUN2 = 0
		    }
		}
	    }
	}
	ACTIVE(Proj_Num = 5):			//614left
	{
	    SELECT
	    {
		ACTIVE(Proj_Control = 'PON'):
		{
		    IF(PROJ_POWER3 = 0)
		    {
			SEND_STRING dvProj614Lt,'(PWR1)'
			WAIT 25
			{
			    RUN3 = 1
			}
		    }
		}
		ACTIVE(Proj_Control = 'POF'):
		{
		    IF(PROJ_POWER3 = 1)
		    {
			SEND_STRING dvProj614Lt,'(PWR0)'
			RUN3 = 0
		    }
		}
	    }
	}
	ACTIVE(Proj_Num = 6):			//BOTH
	{
	    SELECT
	    {
		ACTIVE(Proj_Control = 'PON'):
		{
		    IF(PROJ_POWER2 = 0)
		    {
			SEND_STRING dvProj614Rt,'(PWR1)'
			WAIT 25
			{
			    RUN2 = 1
			}
		    }
		    IF(PROJ_POWER3 = 0)
		    {
			SEND_STRING dvProj614Lt,'(PWR1)'
			WAIT 25
			{
			    RUN3 = 1
			}
		    }
		}
		ACTIVE(Proj_Control = 'POF'):
		{
		    
		    SEND_STRING dvProj614Rt,'(PWR0)'
		    SEND_STRING dvProj614Lt,'(PWR0)'
		    RUN2 = 0
		    RUN3 = 0
		}
	    }
	}
    }
}
DEFINE_CALL 'Proj Control'(integer Proj_Num, char Proj_Control[10]) //Projector Control Sub.
{
    LOCAL_VAR CHAR CMD[10]
    DISPLAY = Proj_Num
    SELECT
    {
	ACTIVE(Proj_Control = 'VID1'):
	{
	    //SEND_STRING dvProjB,'(SRC2)'
	    CMD = '(SRC2)' 
	}
	ACTIVE(Proj_Control = 'VID2'):
	{
	    //SEND_STRING dvProjB,'(SRC3)'
	    CMD = '(SRC3)'
	}
	ACTIVE(Proj_Control = 'VID3'):
	{
	    //SEND_STRING dvProjB,'(SRC4)'
	    CMD = '(SRC4)'
	}
	ACTIVE(Proj_Control = 'RGB1'):
	{
	    //SEND_STRING dvProjB,"'(SRC0)'"
	    CMD = '(SRC0)'
	}
	ACTIVE(Proj_Control = 'RGB2'): 
	{
	    //SEND_STRING dvProjB,"'(SRC1)'"
	    CMD = '(SRC1)'
	}
	ACTIVE(Proj_Control = 'RGB3'):
	{
	    //SEND_STRING dvProjB,"'(SRC5)'"
	    CMD = '(SRC5)'
	}
    }
    SELECT
    {
	ACTIVE(Proj_Num = 3):
	{
	    SEND_STRING dvProj614Rt,CMD
	}
	ACTIVE(Proj_Num = 4):
	{
	    SEND_STRING dvProj614Rt,CMD
	}
	ACTIVE(Proj_Num = 5):
	{
	    SEND_STRING dvProj614Lt,CMD
	}
	ACTIVE(Proj_Num = 6):
	{
	    SEND_STRING dvProj614Rt,CMD
	    SEND_STRING dvProj614Lt,CMD
	}
    }
}


DEFINE_CALL 'Matrix'(integer nIn,integer nOut,Char Clvl)	//! = A&V, & = Video, $ = Audio
{
    Call 'QUEUE ADD'(dvMatrix,"itoa(nIn),'*',itoa(nOut),cLvl",5,0)
    SEND_STRING 0:1:0,"'dvMatrix IN ',itoa(nIn),' to OUT ',itoa(nOut),13,10"
}
DEFINE_CALL 'System Off'(Char nRoom[3])
{
    If(nRoom = '612')
    {
	Call 'Proj Power'(ProjCenter612,'POF')
	AUDIA_SetVolumeFn (2, AUDIA_VOL_MUTE)
	AUDIA_SetVolumeFn (6, AUDIA_VOL_MUTE)
	Call'Power Relay'(0,1)
    }
    If(nRoom = '614')
    {
	Call 'Proj Power'(ProjLeft614,'POF')
	Call 'Proj Power'(ProjRight614,'POF')
	AUDIA_SetVolumeFn (1, AUDIA_VOL_MUTE)
	AUDIA_SetVolumeFn (5, AUDIA_VOL_MUTE)
	Call'Power Relay'(0,2)
    }

    Send_string 0:1:0,"'Need to MUTE the AUDIO',13,10"
}

DEFINE_CALL 'AUDIO_MUTE'(integer audio_channel) {
    IF(uAudiaVol[audio_channel].nMute)
	{
          AUDIA_SetVolumeFn (audio_channel, AUDIA_VOL_MUTE_OFF)
	}
        ELSE
	{
          AUDIA_SetVolumeFn (audio_channel, AUDIA_VOL_MUTE)
	}


}
DEFINE_CALL 'AUDIO_UP'(integer audio_channel) {
    IF(uAudiaVol[audio_channel].nMute)
	{
          AUDIA_SetVolumeFn (audio_channel, AUDIA_VOL_MUTE_OFF)
	}
        ELSE
	{
          AUDIA_SetVolumeFn (audio_channel, AUDIA_VOL_UP)
	}

}

DEFINE_CALL 'AUDIO_DOWN'(integer audio_channel) {
    IF(uAudiaVol[audio_channel].nMute)
	{
          AUDIA_SetVolumeFn (audio_channel, AUDIA_VOL_MUTE_OFF)
	}
        ELSE
	{
          AUDIA_SetVolumeFn (audio_channel, AUDIA_VOL_DOWN)
	}

}

DEFINE_CALL 'AUDIO_START' {
	    send_string dvAudia1,"'SET 2 INPMUTE 22 9 0',10"
	    send_string dvAudia1,"'SET 2 INPMUTE 22 10 0',10"
	    
	    send_string dvAudia1,"'SET 2 INPMUTE 22 5 0',10"
	    send_string dvAudia1,"'SET 2 INPMUTE 22 6 0',10"



}
(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)


DEFINE_START
PowerState[1] = 0
PowerState[2] = 0
FOR (COUNT=0 ; COUNT<70 ; COUNT++)
{
    TimeArray[Count] = 1000
}
TIMELINE_CREATE(TL2, TimeArray, 50, TIMELINE_RELATIVE, TIMELINE_REPEAT) 
(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT
DATA_EVENT[dvAudia1]	
{
    Online:
    {
	SEND_COMMAND dvAudia1,"'SET BAUD 38400,8,N,1'"
	Wait 10
	{
	    	    //Computer Volume
	    AUDIA_AssignVolumeParms (19, dvAUDIA1, 'SET 2 FDRLVL 19 1 ', 'SET 2 FDRMUTE 19 1 ', -18, 12)
	    //614 Mic
	    AUDIA_AssignVolumeParms (20, dvAUDIA1, 'SET 2 FDRLVL 20 1 ', 'SET 2 FDRMUTE 20 1 ', -18, 12)

	    //////////////////////Room 612//////////////////////
	    
	    //Unmutes Computer audio on input matrix
	    //AUDIA_AssignVolumeParms (42, dvAUDIA1, 'SET 2 INPLVL 22 5 ', 'SET 2 INPMUTE 22 5 ', -18, 12 )
            //AUDIA_AssignVolumeParms (43, dvAUDIA1, 'SET 2 INPLVL 22 6 ', 'SET 2 INPMUTE 22 6 ', -18, 12 )

	    //Computer Volume
	    AUDIA_AssignVolumeParms (17, dvAUDIA1, 'SET 2 FDRLVL 17 1 ', 'SET 2 FDRMUTE 17 1 ', -18, 12)
	    //Podium Mic
	    AUDIA_AssignVolumeParms (30, dvAUDIA1, 'SET 2 FDRLVL 30 1 ', 'SET 2 FDRMUTE 30 1 ', -18, 12)
	    //612 Wireless Mic
	    AUDIA_AssignVolumeParms (21, dvAUDIA1, 'SET 2 FDRLVL 21 1 ', 'SET 2 FDRMUTE 21 1 ', -18, 12)
	    //612 Mixer for master volume
	    AUDIA_AssignVolumeParms (32, dvAUDIA1, 'SET 2 FDRLVL 32 1 ', 'SET 2 FDRMUTE 32 1 ', -18, 12)
	}
    }
}

DATA_EVENT[dvMatrix]
{
    Online:
    {
	SEND_COMMAND dvMatrix,"'SET BAUD 9600,8,N,1'"
    }
}

DATA_EVENT[dvProj612]
{
    Online:
    {
	SEND_COMMAND data.device,"'SET BAUD 9600,8,N,1'" //Baud Rate of the Proj
	PROJ_POWER1 = 0
    }
     STRING:
    {
             
	LOCAL_VAR X
        PROJ_BUFFER1 = DATA.TEXT
        X = LENGTH_STRING(PROJ_BUFFER1)
        IF(X > 2)
        {
            SELECT
            {
                ACTIVE (MID_STRING(PROJ_BUFFER1,5,1) = '0'):PROJ_POWER1 = 0 //OFF
                ACTIVE (MID_STRING(PROJ_BUFFER1,5,1) = '1'):PROJ_POWER1 = 1 //ON
	    }
            SET_LENGTH_STRING(PROJ_BUFFER1,0)
            PROJ_BUFFER1 = '' 
	}
    }
}
DATA_EVENT[dvProj614Lt]
{
    Online:
    {
	SEND_COMMAND data.device,"'SET BAUD 19200,8,N,1'" //Baud Rate of the Proj
	PROJ_POWER2 = 0
	
    }
     STRING:
    {
             
        LOCAL_VAR X
        PROJ_BUFFER3 = DATA.TEXT
        X = LENGTH_STRING(PROJ_BUFFER3)
        IF(X > 2)
        {
            SELECT
            {
                ACTIVE (MID_STRING(PROJ_BUFFER3,5,1) = '0'):PROJ_POWER3 = 0 //OFF
                ACTIVE (MID_STRING(PROJ_BUFFER3,5,1) = '1'):PROJ_POWER3 = 1 //ON
	    }
            SET_LENGTH_STRING(PROJ_BUFFER3,0)
            PROJ_BUFFER3 = '' 
	}
    }
}
DATA_EVENT[dvProj614Rt]
{
    Online:
    {
	SEND_COMMAND data.device,"'SET BAUD 19200,8,N,1'" //Baud Rate of the Proj
	PROJ_POWER2 = 0
	
    }
     STRING:
    {
             
        LOCAL_VAR X
        PROJ_BUFFER2 = DATA.TEXT
        X = LENGTH_STRING(PROJ_BUFFER2)
        IF(X > 2)
        {
            SELECT
            {
                ACTIVE (MID_STRING(PROJ_BUFFER2,5,1) = '0'):PROJ_POWER2 = 0 //OFF
                ACTIVE (MID_STRING(PROJ_BUFFER2,5,1) = '1'):PROJ_POWER2 = 1 //ON
	    }
            SET_LENGTH_STRING(PROJ_BUFFER2,0)
            PROJ_BUFFER2 = '' 
	}
    }
}
DATA_EVENT[dvTpBoth]
{
    Online:
	SEND_COMMAND data.device,"'Page-Splash'"
}

BUTTON_EVENT[dvTpBoth,nProjAdvance]
{
    Push:
    {
	switch (get_last(nProjAdvance))
	{
	    Case 1:
	    {
		Call 'Proj Power'(ProjCenter612,'PON')
		
		
	    }
	    Case 2:
	    {
		Call 'Proj Power'(ProjCenter612,'POF')
	    }
	    Case 3:
	    {
		Call 'Proj Power'(ProjRight614,'PON')
	    }
	    Case 4:
	    {
		Call 'Proj Power'(ProjRight614,'POF')
	    }
	    Case 5:
	    {
		Call 'Proj Power'(ProjLeft614,'PON')
	    }
	    Case 6:
	    {
		Call 'Proj Power'(ProjLeft614,'POF')
	    }
	    
	}
    }
}


(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
(***********************************************************)
BUTTON_EVENT[dvTpBoth,nBtnPodiumLoc]
{
    Push:
    {   
        send_string 0:1:0,"'tp is ',itoa(get_last(dvTpBoth)),13,10"
        //send_string 0:1:0,"'btn is ',itoa(nBtnPodiumLoc),13,10"
        SWITCH(get_last(dvTpBoth))
        {
            Case 1:     //612
            {
                Switch (button.input.channel)
                {
                    Case nRight:
                    {
                        nPodiumLocation[(get_last(dvTpBoth))] = 3       //3 is the sw input #
                    }
                    Case nLeft:
                    {
                        nPodiumLocation[(get_last(dvTpBoth))] = 4       //4 is the sw input #
                    }
                }    
            }
            Case 2:     //614
            {
                Switch (button.input.channel)
                {
                    Case nRight:
                    {
                        nPodiumLocation[(get_last(dvTpBoth))] = 1       //1 is the sw input #
                    }
                    Case nLeft:
                    {
                        nPodiumLocation[(get_last(dvTpBoth))] = 2       //2 is the sw input #
                    }
                }
            }
        }
    }
}
BUTTON_EVENT[dvTpBoth,nBtnDest]	//Select Left/Right/Both Projs
{
    Push:
    {
	Switch (get_last(nBtnDest))
	{
	    Case 1:	//Left Proj
	    {
		IF(PROJ_POWER3 = 0)
		{
		    CALL 'Proj Power'(ProjLeft614,'PON')
		}
		WAIT_UNTIL (RUN3 = 1)
		{
		    SWITCH (nCurrentSource[get_last(dvTpBoth)])
		    {
			
			Case nPC:
			{
			    
			    Call 'Matrix'(nPodiumLocation[2],2,'&') //VIDEO
			    Call 'Matrix'(nPodiumLocation[2],1,'$') //AUDIO
			}
		    }
		}
	    }
	    Case 2:	//Right Proj
	    {
		IF(PROJ_POWER2 = 0)
		{
		    CALL 'Proj Power'(ProjRight614,'PON')
		}
		WAIT_UNTIL (RUN2 = 1)
		{
		    SWITCH (nCurrentSource[get_last(dvTpBoth)])
		    {
			
			Case nPC:
			{
			    
			    Call 'Matrix'(nPodiumLocation[2],1,'&')//VIDEO
			    Call 'Matrix'(nPodiumLocation[2],1,'$')//AUDIO
			}
		    }
		}
	    }
	    Case 3:	//BOTH PROJECTORS)
	    {
		IF(PROJ_POWER2 = 0)
		{
		    CALL 'Proj Power'(ProjRight614,'PON')
		}
		IF(PROJ_POWER3 = 0)
		{
		    CALL 'Proj Power'(ProjLeft614,'PON')
		}
		WAIT_UNTIL((RUN2 = 1) && (RUN3 = 1))
		{
		    SWITCH (nCurrentSource[get_last(dvTpBoth)])
		    {
			
			Case nPC:
			{

			    Call 'Matrix'(nPodiumLocation[2],1,'&')//VIDEO
			    Call 'Matrix'(nPodiumLocation[2],2,'&')//VIDEO
			    Call 'Matrix'(nPodiumLocation[2],1,'$')//AUDIO
			}
		    }
		}
            }			
	}
    }
}
BUTTON_EVENT[dvTpBoth,nSrcSelects]
{
    Push:
    {

        If (button.input.device.number = 10005)
        {
            IF(PROJ_POWER1 = 0)
            {
                CALL 'Proj Power'(ProjCenter612,'PON')
            }
	    Call 'Matrix'(nPodiumLocation[1],3,'!')
	    Call 'Matrix'(nPodiumLocation[1],6,'&')
	     Call 'Matrix'(nPodiumLocation[1],8,'&')
	    Call 'Matrix'(5,6,'$')
	    Call 'Matrix'(5,8,'$')
           
        }
        nCurrentSource[get_last(dvTpBoth)] = nPC
           
        

    }
}
BUTTON_EVENT[dvTpBoth,nBtnPwrOff]
{
    Push:
    {
	Switch (get_last(dvTpBoth))
	{
	    Case 1:
	    {
		Call 'System Off'('612')
	    }
	    Case 2:
	    {
		Call 'System Off'('614')
	    }
	}
    }
}
BUTTON_EVENT[dvTpBoth,8]	//This is on the Splash page. Basically a big translucent button.
{
    Push:
    {
	Switch (get_last(dvTpBoth))
	{
	    Case 1:
	    {
		Call 'Power Relay'(1,1)
		Call 'AUDIO_START'
	    }
	    Case 2:
	    {
		Call 'Power Relay'(1,2)
		Call 'AUDIO_START'
	    }
	}
    }
}

BUTTON_EVENT[dvTp612,nRoomMode]
{
    Push:
    {
	SWITCH(button.input.channel)
	{
	    Case 12:	//Normal
	    {
		RoomCombineMode = 0
		//SEND_COMMAND dvTp612,"'PPOF-Room in use'"
		//Mute All First
		send_string dvAudia1,"'SET 2 RTRMUTEXP 33 1 1 0',10"
		send_string dvAudia1,"'SET 2 RTRMUTEXP 33 1 2 0',10"
		send_string dvAudia1,"'SET 2 RTRMUTEXP 33 2 1 0',10"
		send_string dvAudia1,"'SET 2 RTRMUTEXP 33 2 2 0',10"
		
		//Enable audio routing to individual rooms
		send_string dvAudia1,"'SET 2 RTRMUTEXP 33 1 1 1',10"
		send_string dvAudia1,"'SET 2 RTRMUTEXP 33 2 2 1',10"
	    }
	    Case 13:	//Expanded or Combined
	    {
		    //Mute All First
		    send_string dvAudia1,"'SET 2 RTRMUTEXP 33 1 1 0',10"
		    send_string dvAudia1,"'SET 2 RTRMUTEXP 33 1 2 0',10"
		    send_string dvAudia1,"'SET 2 RTRMUTEXP 33 2 1 0',10"
		    send_string dvAudia1,"'SET 2 RTRMUTEXP 33 2 2 0',10"
		    //Enable routing of audtio to entire room
		    send_string dvAudia1,"'SET 2 RTRMUTEXP 33 1 1 1',10"
		    send_string dvAudia1,"'SET 2 RTRMUTEXP 33 1 2 1',10"
		    RoomCombineMode = 1
		
	    }
	    
	}
    }
}
BUTTON_EVENT[dvTp614,CombineRooms]// BTN41 //YES - Combine the two rooms
{
    Push:
    {
	RoomCombineMode = 1
	SEND_COMMAND dvTp612,"'PPON-Room in use'"
	send_string dvAudia1,"'SET 2 RTRMUTEXP 33 2 2 1',10"
	send_string dvAudia1,"'SET 2 RTRMUTEXP 33 2 1 1',10"
    }
}
BUTTON_EVENT[dvTp612,43]	//612 wants to override the Expanded mode
{
    Push:
    {
	RoomCombineMode = 0
	SEND_COMMAND dvTp614,"'PPON-Room combine override'"
	SEND_COMMAND dvTp612,"'PPOF-Room in use'"

    }
}

(*-- Level 1 ----------------------------------------------*)

BUTTON_EVENT[dvTp614,204]        // Vol Up
BUTTON_EVENT[dvTp614,205]        // Vol Down
BUTTON_EVENT[dvTp614,206]        // Vol Mute
{
    PUSH :
    { 
	STACK_VAR INTEGER nVolChn
	nVolChn = 1
	SWITCH(BUTTON.INPUT.CHANNEL)
	{
	    CASE 204 :    // Vol Up
	    {
		IF(uAudiaVol[nVolChn].nMute)
		{
		    AUDIA_SetVolumeFn (nVolChn, AUDIA_VOL_MUTE_OFF)
		}
		ELSE
		{
		    AUDIA_SetVolumeFn (nVolChn, AUDIA_VOL_UP)
		}
	    }
	    CASE 205 :    // Vol Down
	    {
		IF(uAudiaVol[nVolChn].nMute)
		{
		    AUDIA_SetVolumeFn (nVolChn, AUDIA_VOL_MUTE_OFF)
		}
		ELSE
		{
		    AUDIA_SetVolumeFn (nVolChn, AUDIA_VOL_DOWN)
		}
	    }
	    CASE 206 :    // Vol Mute
	    {
		IF(uAudiaVol[nVolChn].nMute)
		{
		    AUDIA_SetVolumeFn (nVolChn, AUDIA_VOL_MUTE_OFF)
		}
		ELSE
		{
		    AUDIA_SetVolumeFn (nVolChn, AUDIA_VOL_MUTE)
		}
	    }
	}
	AUDIA_MatchVolumeLvl (5,1)      // Example: If this was a stereo pair
    }
    RELEASE :
    {
	AUDIA_SetVolumeFn (1, AUDIA_VOL_STOP)
    }
    HOLD[3,REPEAT] :
    {
	AUDIA_MatchVolumeLvl (5,1)      // Example: If this was a stereo pair
    }
}


BUTTON_EVENT[dvTp612,214]        // Vol Up
{
    PUSH :
    { 
	STACK_VAR INTEGER audio_channel 
	audio_channel = 32
	Call 'AUDIO_UP'(audio_channel)
    }
}
BUTTON_EVENT[dvTp612,215]        // Vol Down
{
    PUSH :
    { 
	STACK_VAR INTEGER audio_channel 
	audio_channel = 32
   
	Call 'AUDIO_DOWN'(audio_channel)
     
    }
}

BUTTON_EVENT[dvTp612,216]        // Vol Mute
{
    PUSH :
    { 
	STACK_VAR INTEGER audio_channel 
	audio_channel = 32
	CALL 'AUDIO_MUTE'(audio_channel)

    }
}

BUTTON_EVENT[dvTp612,217] {	 // Mute Wireless Mic
    PUSH : {
	STACK_VAR INTEGER audio_channel
	//audio_channel = 29
	audio_channel = 21
	Call 'AUDIO_MUTE'(audio_channel)
    }
}
BUTTON_EVENT[dvTp612,218] {	//Mute Podium Mic
    PUSH : {
	STACK_VAR INTEGER audio_channel
	audio_channel = 30
	Call 'AUDIO_MUTE'(audio_channel)
    }
}
BUTTON_EVENT[dvTp612,219] {	//Mute Computer Vol
    PUSH : {
	STACK_VAR INTEGER audio_channel
	audio_channel = 17
	Call 'AUDIO_MUTE'(audio_channel)
    }
}
BUTTON_EVENT[dvTp612,220] {	//Decrease Vol Wirless Mic
    PUSH : {
	STACK_VAR INTEGER audio_channel
	audio_channel = 21
	Call 'AUDIO_DOWN'(audio_channel)
    }

}
BUTTON_EVENT[dvTp612,221] {	//Decrease Vol Podium Mic
    PUSH : {
	STACK_VAR INTEGER audio_channel
	audio_channel = 30
	Call 'AUDIO_DOWN'(audio_channel)
    }

}
BUTTON_EVENT[dvTp612,222] {	//Decrease Vol Computer

    PUSH : {
	STACK_VAR INTEGER audio_channel
	audio_channel = 17
	Call 'AUDIO_DOWN'(audio_channel)
    }

}
BUTTON_EVENT[dvTp612,223] {	//Increase Vol Wirless Mic
    PUSH : {
	STACK_VAR INTEGER audio_channel
	audio_channel = 21
	Call 'AUDIO_UP'(audio_channel)
    }

}
BUTTON_EVENT[dvTp612,224] {	//Increase Vol Podium Mic
    PUSH : {
	STACK_VAR INTEGER audio_channel
	audio_channel = 30
	Call 'AUDIO_UP'(audio_channel)
    }

}
BUTTON_EVENT[dvTp612,225] {	//Increase Vol Computer
    PUSH : {
	STACK_VAR INTEGER audio_channel
	audio_channel = 17
	Call 'AUDIO_UP'(audio_channel)
    }

}





TIMELINE_EVENT[TL1] // capture all events for Timeline 1 
{ 
    send_string 0:1:0,"itoa(OffTime-timeline.sequence),13,10"
    send_command dvTp612,"'@TXT',2,itoa(OffTime-timeline.sequence)"
    send_command dvTp614,"'@TXT',2,itoa(OffTime-timeline.sequence)"
    Send_command dvTp612,"'beep'"
    Send_command dvTp614,"'beep'"
    switch(Timeline.Sequence) // which time was it? 
    { 
	case 1: 
	    {
		SEND_COMMAND dvTp612,"'Wake'"
		SEND_COMMAND dvTp614,"'Wake'"
		SEND_COMMAND dvTp612,"'PPON-Shutdown Warning'"
		SEND_COMMAND dvTp614,"'PPON-Shutdown Warning'"
	    } 
	case 2: { } 
	case 3: { } 
	case 4: { } 
	case 60: 
		{
		    timeline_kill(tl1)
		    Call 'System Off' ('612')
		    Call 'System Off' ('614')
		    SEND_COMMAND dvTp612,"'PPOF-Shutdown Warning'"
		    SEND_COMMAND dvTp614,"'PPOF-Shutdown Warning'"
		    SEND_COMMAND dvTp612,"'Page-Splash'"
		    SEND_COMMAND dvTp614,"'Page-Splash'"
		    SEND_COMMAND dvTp612,"'Sleep'"
		    SEND_COMMAND dvTp614,"'Sleep'"
		 } 
	
    } 
} 

TIMELINE_EVENT[TL2] // capture all events for Timeline 2
{ 
    switch(Timeline.Sequence) // which time was it? 
    { 
	case 1: 
	    {
		nCheckPwr[1] = 1
		//SEND_STRING dvProj612,"'PWR?'"
	    } 
	case 2: { } 
	case 3:
	    {
		nCheckPwr[2] = 1
		//SEND_STRING dvProj614Lt,"'(PWR?)'"
	    } 
	case 4:
	    {
		nCheckPwr[3] = 1
		//SEND_STRING dvProj614Rt,"'(PWR?)'"
	    } 
    }
}


DEFINE_PROGRAM
If((time_to_hour(time) = 21)&&(time_to_minute(time) = 00)&&(nTimeBlock = 0))
{
    send_string 0:1:0,"'the time is ',time,13,10"
    nTimeBlock = 1		//Keeps this from running over and over for the whole minute.
    TIMELINE_CREATE(TL1, TimeArray, 61, TIMELINE_RELATIVE, TIMELINE_ONCE) 
    wait 620			//Need to wait until the minute is over.
	nTimeBlock = 0	
}

[dvTp612,214] = (uAudiaVol[2].nVolRamp = AUDIA_VOL_UP)
[dvTp612,215] = (uAudiaVol[2].nVolRamp = AUDIA_VOL_DOWN)
[dvTp612,216] = (uAudiaVol[2].nMute)
[dvTp614,204] = (uAudiaVol[1].nVolRamp = AUDIA_VOL_UP)
[dvTp614,205] = (uAudiaVol[1].nVolRamp = AUDIA_VOL_DOWN)
[dvTp614,206] = (uAudiaVol[1].nMute)

//Sets visual Audio level graph on touch screen
SEND_LEVEL dvTp614,1,AUDIA_GetBgLvl(1)
SEND_LEVEL dvTp612,2,AUDIA_GetBgLvl(2)
 

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)

