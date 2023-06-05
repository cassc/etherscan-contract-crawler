// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ThankYouX + mpkoz
/// @author: manifold.xyz

import "@manifoldxyz/creator-core-solidity/contracts/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    WWW&2ixxxxxxxxxxxxxxxiBWWWN$$$$$$$$$$$$$$$$$$$BWWWQxxxxxxxxxxxxxxxxxlbWWWWWWWNB&gm$$$$$$$$$$$$&WWWWoxxxxiUBWWWWWWWWWWWWW    //
//    WWBixxxxxxxxxxxxxxxxxx#WWWWD$$$$$$$$$$$$$$$$$$gWWWNsxxxxxxxxxixxxxoDWWWWWWWWWWWWWWNB&0gD$$$$$$mWWWWqxxuUBWWWWWWWWWWWWWWW    //
//    WWWwxxxxxxxxxxxxxxxxxjL0WWW0$$$$$$$$$$$$$$$$$$$NWWWSxxxxxxxxxxxiEBWWWWWWWWWWWWWWWWNWWWWWWN&0QD$NWWWWggWWWWWWWWWWWWWWWWWW    //
//    WWW$xxxxxxxxxxxxxxx>.. `?NWM$$$$Utr^?2$$$$UouixHWWW&ixxxxxxxxuSBWWWWWWWWWWWWWWWWWu"!_;xWW&}cc{bWWWWWWB#&WWWWWWWWWWWWWWWW    //
//    WWWNxxxxxxxxxxxxxxi\     aWWNB0g*    _R$$$_    !NWWWa?!!!|)2&WWWWWWWj|~_`^UWWWWWWP,\. ^WQ,    ;MWWN2~   "iNWWWWWWWWWWWWW    //
//    WWWW%xxxxxxxxxxxxxx=     sWWWWWWr    .H$$R_    .$WWW8!    `?NWWWWWWWr     `oWWWWWi    `HI     |N&u,    `\DWWWWWWWWWWWWWW    //
//    WWWW$xxxxxxxxxxxxxFP.    jWWWWWW>    ;WNMBr    `wWWWB.      _5WWWWWW7       |&WWWa     xu     ;^`    .c0WWWWWWWWWWWWWWWW    //
//    MWWWNuxxxxxxxxxuU&WQ.    7WWWWWW?    |Q0BM*    `2WWWH        `JNWWWWj        ;gWWM=    cV         `~FB#kUQBWWWWWWWWWWWWW    //
//    gWWWW5xxxxxxxjtwwoox.    ~sicji#=               sWWW>          ;&WWWi         ,0WW$    =k`        .*UNsxxxxiywSD&WWWWWWW    //
//    DNWWW0xxxxxF9_                 ct               iWWk`    \,     ;DWWZ`         _#W&    |#`           ;r7xxxxxxxxxuFPd&NW    //
//    $&WWWWwxuSBW5;,,,,"_`    `;!~|}Mx    ,>*vv;     iWM!     PF,     `sWQ.     ,    `7U    /$`    ,L|,      _*xixxxxxxxxxxxi    //
//    m&WWWWNgNWWWWWNNNNWM_    \WWWWWWL    !WWWWi     oWw                *B;     Sw;    ;    !7`    -txxjL, ``  "vxxxxxxxxxxxx    //
//    WWWWWWWWWWWWWWWWWWWN;    ~NWWWWWt    ;WWWWu    `uP!                 S*     xWNi.       .*;`  .*xxxuMNk/, "*xixxxxxxxxxxx    //
//    WWWWWWWWWWWWWWWWWWWWr    ;MWWWWWy    ,NWWWI     !?.      `..";^"    ._.    IWWWQ!       rx{vvjiixxxdWWW&Jtxxxxxxxxxxxxxx    //
//    WWWWWWWWWWWWWWWWWWWWQ.   ;BWWWWW&v*)oEWWWWq.    !>     ;kHR$$$$#|    `iurrlNWWWWU\^;;~!;)x7Ljxxxxx7oNWWWUxxxxxxxxxxxxxxx    //
//    WWWWWWWWWWWWWWWWWWWWWQx_\UWWWWWWWNNWWWWWNmj`    !tr;. `P&$$$$$$$$%>|*oR$$$$DNWWWSxxxxxiiJ;   _?x}!  ."xM&xxxxxxxxxxxxxxx    //
//    WWBMWWWW&m8g&NNWWWNU*;xNWWWWWWWNl_,!rx$qux7_`   "xxxkP5WM$$$$$$$Us}r!;t$$$$$&WWW&xxxxxxt;     `;"     ,HWzxxxxxxxxxxxxxx    //
//    quxiNWWWM$$$$$$$QS"    ,iBWWWNu"     ;JxxxxxJj}{jxxxoWWM8uw$$$$$\     ;p$$$$8WWWWZxxxxxxt>`          |BWW8Vuxxxxxxxxxxxx    //
//    xxxx$WWWWQ$$$$$$$$u,     .)gF_     ,rxtv^_,,,_;^>cxxx0\.  ;q$$$$\     ;S$$$$$BWWWmxxxxxxxxL!`      .FWWWWWWWB8Uwyxxxxxxx    //
//    xxxxVWWWW&$$$$$$$$$du!           ;rtt=.          `;7x?    !d$$$$u`    _S$$$$$gWWWNsxxxxxxxxr.       ,zWWWWWWWWWWWW&QpPoi    //
//    xxxxx0WWWND$$$$$$$$$$R2=.     `<PNFL_    _rv)*^.   ,L\    =$$$$$w.    ;p$$$$$$NWWWUxxxxxix~`          *BWWWWWWWWWWWWWWWN    //
//    xxxxxkWWWW0$$$$$$$$$$$$$H~    .QWWw.   `/xixxii}:   ||    |R$$$$9"    ;H$$$$$$&WWW&xxxixj;    ,s&x     .yWWWWWWWWWWWWWWW    //
//    xxxxxuNWWWM$$$$$$$$$$$$$R^     PWWr    |xxxxxxxt;   <>    ;0B&gm9"    ~R$$$$$$8WWWWuxxx};    ^&WWWP;   .iWWWWWWWWWWWWWWW    //
//    xxxxxxRWWWWQ$$$$$$$$$$$$$>     2WWr    /xxxxxix=`  ;RN|    vWWWNv     ~H$$$$$$$NWWWUxxxiFu/*RWWWWWWNo*PNWWWWWWWWWWWWWWWW    //
//    xxxxxx%WWWW&$$$$$$$$$$$$$)     *WW0;   `\Lccj*;`  .SWW6,   `vu)_    `r&M&0Q$$$$BWWW&eeRNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    xxxxxxx0WWWN$$$$$$$$$$$$$2;`   {WWW&!            \$WWWW&r      `_.`*&WWWWWWWNMMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    xxxxxxxUWWWW&gD$$$$$$$$$$$R2**VQWWWWq="`    `.!cRWWWWWWWWqir_,"v%20WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    xxxxxoRNWWWWWWWNNB&gD$$$$$$$$$$$MWWWNuxxc{2&NWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    xxxo0WWWWWWWWWWWWWWWWNB&g8$$$$$$0WWWWExuSMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    uSBWWWWWWWWWWWWWWWWWWWWWWWWNB&gQ&WWWWWNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNBMNWWWWWWWWWWWWWWWWWWWWWWWWWWWBUu    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWo,,xWWWWWWWWWWWWWWWWNUFINWWWg$$$Dg&BNNWWWWWWWWWWWWWWWWWWWQaxxx    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWi  ?WWWWWWWWWWWWWWBSuxxxRWWW&$$$$$$$$$mg&BNWWWWWWWWWWWW$lxxxxx    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWi  ?WWWWWWWWWWWWg%ixxxxxFWWWW$$$$$$$$$$$$$$$mg&MWWWWWQuxxxxxxx    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWRLLLLLL!  ;LLL?LLQWWNqsxxxxxxxxxNWWWQ$$$$$$$$$$$$$$$$$$mNWWWRxxxxxxxx    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNQ0WWWWB$Dg&BNWWWWWE;;;;;;,  .;;;;;;q&PixxxxxxxxxxxRWWW&$$$$$$$$$$$$$$$$$$$&WWWNuxxxxxxx    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNHuxi&WWWN$$$$$$Dg0&BNWWWWWWi  ?WWWWW&Ixxxxxxxxxxxxxx2WWWND$$$$$$$$$$$$$$$$$$QWWWW6xxxxxxx    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWW&6ixxxxUWWWWg$$$$$$$$$$$$8g&BNx  ?WWNHzxxxxxxxxxxxxxxxxx&WWW0$$$$$$$$$$$$$$$$$$$BWWW&xxxxxxx    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWgexxxxxxxsNWWWB$$$$$$$$$$$$$$$$$v  ?WW#xxxxxxxxxxxxxxxxxxxUWWWM$$$$$$$$$$$$$$$$$$$0WWWWixxxxxx    //
//    WWWWWWWWWWWWWWWWWWWWWWWBSuxxxxxxxxxx$WWWW8$$$$$$$$$$$$$$$$wci$WWBixxxxxxxxxxxxxxxxxxuNWWWQ$$$$$$$$$$$$$$$$$$DWWWWkxxxxxx    //
//    BMNWWWWWWWWWWWWWWWWWWB6ixxxxxxxxxxxxwWWWW&$$$$$$$$$$$$$$$$$$mNWWWPxxxxxxxxxxxxxxxxxxxDWWW&$$$$$$$$$$$$$$$$$$$MWWWgxxxxxx    //
//    $$$$mg&BNWWWWWWWWWWDlxxxxxxxxxxxxxxxx&WWWN$$$$$$$$$$$$$$$$$$$&WWW0xxxxxxxxxxxxxxxxxi20WWWWNNB0QD$$$$$$$$$$$$$0WWWWIxxxxx    //
//    $$$$$$$$$m7;!!!!!;_,,,,,,,,,,,,,,,,,,_!!!;___________________;!!!;,,,,,,,,,,,,,,,,,";;!!!!!!;;;;_____________;gWWWdxxxzH    //
//    $$$$$$$$$$\ `vssss*^^||||||||||||||^^|sssst??????????^  `)????xsssL^^|||||||^^^>csssssszsszzzsssssssssszut7_  #WWWNUP0WW    //
//    $$$$$$$$$$\ .kNWWWQxxxxxxxxxxxxxxxxxxxBWWWN$$$$$$$$$$J  .#$$$$0WWWBixxxxxxxxxyqNWWWWWWWWWWWWWWWWWWWWWWWWWWW>  DWWWWWWWWW    //
//    $$$$$$$$$$\ .P&WWNBJxc)*Lxic?*)cxxxx}}UWWNgEwUR$$$$$$J  .#$$$$DN&BM2xxxxxxi2HD$gMWWWWWWWWNMNNNNNNNMMMMWWWWW>  QWWWWWWWWW    //
//    $$$$$$$$$$\ .P8WW? `,``  ,!``` `^xxr` ;P!```  .^Z&0Q$J  .#$$$qc; ,JSxxxxJ\_  ``  ,rgWWWWW*            #WWWW>  QWWWWWWWWW    //
//    $$$$$$$$$$\ .P$NW?  -vc~   >jL` .7E2`  .*UBBgx. `2WWNl  ,b$qv, .uBWWixyi. `7RBBmi, `uWWWWgUUUUUUU7  .iWWWWW>  QWWWWWWWWW    //
//    $$$$$$$$$$\ .P$&W? `vxx>  _xxc. ,gWS`  sWWWWWWR, .dWWI  ,m). ;u0WWWWWNQ, `aWWWWWWB!  iWWWWWWWWWp~ `{BWWWWWW>  QWWWWWW0R8    //
//    $$$$$$$$$$\ .P$QW? .uxx>  ;xiI, "&WS` ,0WWWWWWN/  uWWV  ``  `*&WWWWWWWy  ^NWWWWWWWF  !NWWWWWWNr` ;QWWWWWWWW>  sIUWWWWIxx    //
//    &gm$$$$$$$\ .P$$B? .6ix>  ;qNW" "&WS` ,gWWWWWWN!  VWWI  `tgz` .cWWWWWWe  ;BWWWWWWWi  |NWWWWNi. _aWWWWWWWWWW=  vxxNWWWHxx    //
//    WWWNM&0gD$\ .P$$0? .8ax>  rWWW" "&WS`  }WWWWWWs` ;&WWI  ,NWWq!  ^DWWWWB;  7WWWWWWS, `aWWWWP; `iMWWWWWWWWNdl_  vxxQWWWBux    //
//    WWWWWWWWWWr .UD$mv .8N$s  rWWW, "&WS`  `_7eex;  ;&WWWI  ,NWWWWa: `r0WWW&^  ;jwai!  !#WWWg=  `=jjJjjccc?oixx_  vxxwWWWWkx    //
//    WWWWWWWWWW* ,&WNNi_;gWWS__{WWW^_^&WS` "6}!.`.;*aNWWWWP__^NWWWWW&;.,^QW&$RFr_.``,;*wNWWWWV___________..,?xxx_  vxxi&WWWgx    //
//    WWWWWWWWWW* ,&WWWWWWWWWWWWWWWWWWWWWS` "&WWWWWWWWWWWWWWWWWWWWW&EuxxmWWWB$$$$$$bbD0&BNWWWWWWWWWWWWWNdlxxxxxxx_  vixxUWWWWF    //
//    WWWWWWWWWW* .8MNNNNNNNNNNNNMMMMMNNNk` "gNNNNNNNNNNNMMMNNNNMQo}}}}}INNNBpSSSSSSSSSSSS#$Q&&MNNNNN&6i}}}}}}}}}_  vxxxyNWWWH    //
//    WWWWWWWWWW*                                                                                                   vxxxxmWWWM    //
//    WWWWWWWWWWmaPPPPPPPPPPPeuusIwPPPPPPPPPPPaaPPPPPaPPPPPasr>>>>>>>>>>>{PPP2iiiiiiiiiiiiiiiiiiisPPPer>>>>>>>>>>>>>JxxxxwWWWW    //
//    WWWWWWWWWWWWWWW&UyiBWWWM$$$$$Dg&&MNWWWWWWWWWWWWWWWWWgoxxxxxxxxxxxxxzWWWWm$$$$$$$$$$$$$$$$$$DNWWWPxxxxxxxxxxxxxxxxxxi&WWW    //
//    WWWWWWWWWWWWWB5ixxxHWWWWg$$$$$$$$$$mg&BNWWWWWWWWWN$FxxxxxxxxxxxxxxxxBWWW0$$$$$$$$$$$$$$$$$$$&WWWgxxxxxxxxxxxxxxxxxxoBWWW    //
//    WWWWWWWWWWN$oxxxxxxyNWWWB$$$$$$$$$$$$$$$$80&NWWWWixxxxxxxxxxxxxxxxxxSWWWN$$$$$$$$$$$$$$$$$$$gWWWWFxxxxxxxxxxxxxxiS&WWWWW    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TYXMK is ERC721Creator {
    constructor() ERC721Creator("ThankYouX + mpkoz", "TYXMK") {}
}