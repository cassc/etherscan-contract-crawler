// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Amydoodles
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//    ........................................................................................................................    //
//    .. ...............,MMO  ....... ..  ..  ... ..  .. ... .. ......  .. ... ....... ............ .ZMM, .. ....... .........    //
//    ................MMMMMMMMMM ................................................................MMMMMMMMMM...................    //
//    .. ............ MMMMMMMMMMMM  ......... ......  .............................. ........ .MMMMMMMMMMMM ...... ...........    //
//    ............... MMMM:   MMMMM  .........................................................MMMMM  .,MMMM...................    //
//    ................ MMMMM O. MMMM ........................................................MMMM .D.MMMMM. ..................    //
//    ..................MMMMN D. MMMM.......................................................MMMM..+ MMMMM.....................    //
//    ...................MMMM  .. MMM...................................................... MMM= . ,MMMM .....................    //
//    ................. MMMM: ... MMM.......................DMMMMMMMN   ................... MMM:... ~MMMM ....................    //
//    ................NMMMM8.....MMMM.................MMMMMMMMMMMMMMMMMMMMM.................MMMM ... OMMMMD...................    //
//    ...............MMMMM= .....MMMD......... . MMMMMMMMMMMMMMMNMMMMMMMMMMMMMMM ...........?MMM .... ,MMMMM .................    //
//    .............OMMMMM. M....MMMM.........,MMMMMMMMMMMM. . ...... ..MMMMMMMMMMMM:.........MMMM....M  MMMMMI ...............    //
//    ............MMMMMM.,M ...MMMM.,.....=MMMMMMMMM$ .  .................  ZMMMMMMMMM?...... MMMN..  D  8MMMMM...............    //
//    ...........NMMMM........ MMM  ....MMMMMMMMN.............................. NMMMMMMMN.....,MMM........ MMMMN..............    //
//    ......... ZMMMMM........MMMM....8MMMMMMM ..................................  NMMMMMMN....OMMM....... 8MMMM+ ............    //
//    ......... MMMM =........MMM ..IMMMMMM. .......................................  MMMMMM8...MMM ...... O.MMMM ............    //
//    .........MMMM..M........MM8 .MMMMMM. OMN77DMM. .........................MMN77MM$. MMMMMM  +MM .......M. MMMM ...........    //
//    .........MMMM M ........MM.+MMMMM.~M...  .....M.......................M. ..... ..M:.MMMMMZ.MM.........N.OMMM ...........    //
//    ........~MMM,. .........MMNMMMM,.M .MMMMMMM,...M.................... M...=MMMMMMM .M =MMMMMMM.......... ,MMMZ...........    //
//    ........MMMM ............MMMMM. O.MMMMMMMMMMM...?...................: ..MMMMMMMMMMM.+. MMMMM ............MMMM ..........    //
//    ........MMMMM...........MMMM? .: MMMMMMMMMMMM...M...................M ..MMMMMMMMMMMM.?..OMMMM.......... MMMMM ..........    //
//    ........$MMM.M........ MMMM...M.MMMMM. . IMMM,..M...................M ..MMMD... MMMMM M.  MMMM.........N.MMMM...........    //
//    ........ MMM+ Z.......~MMM......MMM$ ... NMMM ..M...................O...MMMM.....+MMM  ,.. MMM,.......~..MMM............    //
//    .........MMMM ~...... MMM... M..MMM....  MMMM. ,.................... +..MMMM......MMM. M....MMM ........MMMM ...........    //
//    ......... MMMM.......?MMD....M .MMMN,...MMMM:..M ................... M.. MMMM... ZMMM..M....IMMD ..... MMMM.............    //
//    ......... ?MMMM:~....MMM.... M .,MMMMMMMMMM7..D.......................$ .DMMMMMMMMMM . M.....MMM.. .~~MMMM,.............    //
//    .......... +MMMM  .:MMMM.... :,.. MMMMMMMM?...7 ......................N~..,MMMMMMMM... $.... MMMM,...MMMM8..............    //
//    ............=MMMM =MMMMMM. ...M...  MMMM .. ~N.........................$?..  MMMM ... M.....MMMMMM+ MMMM$...............    //
//    ............. MMMMMMMMMMM..... M ..........M ............................M.......... M ....,MMMMMMMMMMM ................    //
//    ............MMMMMMMM.  ........  MM,...~MM ................................MM= ...MM ........ .  MMMMMMMM...............    //
//    ..........MMMMMMZ ............................... ?  .  =MMMI   . + ............................... DMMMMMM. ...........    //
//    ........?MMMMM  ..................................:MMMMMMMMMMMMMMM+....................................MMMMMO ..........    //
//    .......NMMMM, .......................................7MMM.  NMM$ ......................................, MMMMM .........    //
//    ......MMMMZ ..............................................................................................NMMMM.........    //
//    .... MMMM ...... .  . .....      ,,,~7IIIIIII,,,,,,,,,,7DNIDD7,,,,,,,,,,?IIIIIII~,,,      . .. .... ........MMMM........    //
//    ... MMMM ...8MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM....MMMM ......    //
//    .. MMMM.....MM..,=7$$DNNNNNNNNNN877::...........................................::77ONNNNNNNNNNDZ$7+, .MM ....MMMM......    //
//    ...MMM......MM.........................................................................................MM..... MMM......    //
//    ..MMMM.... 7MM.........................................................................................MMN.... MMMM.....    //
//    . MMMM ....MMM ...................................................... ... ....... ... ............. ...MMM.....$MMM ....    //
//    ..MMM,.... MMM......MM. ..MM  . MM MM...MM MMMMM ....ZMMMM... .MMMM: . MMMMM, . M ....MMMMMM. MMMM ....MMM......MMM.....    //
//    . MMM .... MMM.....,MMM ..MMM..MMM..MN.MM..MM.  MM  MN...,M .DM... MM  M.   MN  M ... MI.....NM.. M ...MMM  ... MMM ....    //
//    . MMM..... MMM ....M~.M ..MM MM MM...M7M ..MM....M..M ... MM MM.... M  M....MM  M ....MMMMM ..MMMM ....MMM......MMM.....    //
//    ..MMMZ.....MMM....DMMMMM..MM.. .MM... M ...MM.  DM. M.... M$.MM... NM  M. ..MM  M ... MI.... , .. M ...MMM.....=MMM.....    //
//    ..MMMM.... MMM ...M....M$ MM  ..MM... M ...MMMMMM... MMMMM$ ..MMMMMM,. MMMMMM.. MMMMM.MMMMMM.:MMDMM....MMM.... MMMM ....    //
//    ...MMM,....MMM............ ..... ..... ........  .....  . ..... ....... .. .... ..  .. .    . . .  ....MMM.... MMM,.....    //
//    ...MMMM ...:MM~........................................................................................MM$... MMMM......    //
//    ... MMM?....MMN.......................................................................................$MM ...8MMM: .....    //
//    ... MMMM ...MMM.................... .. :=$NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN$~:.  .  ..................MMM....MMMM ......    //
//    .....MMMM...?MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMD...MMMM........    //
//    .... DMMM....$MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM=....MMMM........    //
//    ......MMMM......D..MMM.DMN.    .  I MMM .MM.......,.. MMM .,MMM...+.......MM  MMM 8  .     MMM MMM..7 .....MMMM.........    //
//    ......?MMM...... N.MMMD+MM........M+MMM.MMM ......~ .MMMM...MMMM..$...... MMN MMM8M .......MM8MMMO.~. .... MMM8.........    //
//    .......MMMD.......N.MMM MMM ...... MMMM.MMM....... M=MMM~... MMM,N....... MMM.MMMM........MMM MMM.N ..... MMMM..........    //
//    .......DMMM ....... MMM MMM:.......MMMM.MMM ........MMMM ....MMMM .......~MMM.MMMM...... .MMM.MMM ........MMM7..........    //
//    ........MMM ...... NMMM 8MMM.......MMMM MMMM...... NMMMM.....MMMMM.......MMMM MMMM...... MMMM MMMM .......MMM...........    //
//    ........MMMD.....:. MMM..MMMD ....M+MMM.8MMM .....+ MMMM.....MMMM.O .....MMM+ MMM8M.....MMMM..MMM. ?.....IMMM ..........    //
//    ........MMMM.... $  MMM..MMMM .... .MMM .MMMM.....M.MMMM ....MMMM M.....DMMM..MMM,.= .. MMMM..MMM .~. ...MMMM...........    //
//    ........MMMM .... ..MMM..~MMM?...:..MMM .MMMM.....M MMMM ....MMMM.M . ..MMMM..MMM  ?  ..MMM...MMM . . . .MMMM . ... ....    //
//    ........MMMM.....D 8MM8 ..MMMM ...M.MMM$..MMM$.....=MMMM ....MMMM,  .. :MMM? :MMM.M....MMMM . NMMI.I. ...MMMM...........    //
//    ....... MMM..... , MMM. . MMMM ... MNMMM..MMMM......MMMM.....MMMM....  MMMM .MMMMM... .MMMM .. MMM.=... . MMM.. ... ....    //
//    .......MMMN ......,MMM....MMMM......MMMM..MMMM......:MMM ... MMM. .... MMMM. MMMM......MMMM... MMM?.......MMMM..........    //
//    ......MMMM  ....,NMMM,....MMMM .....NMMM..MMMM...... MMM=....MMM...... MMMM..MMMM......MMMM ... MMM8 ..... MMMM.........    //
//    ...  MMMM ...  ? DMMM....MMMM~..... NMMM..?MMM ... M MMM8...+MMM.M....,MMMN. MMMM...... MMMM....MMMM ,  ....MMMM. ......    //
//    ....MMMM......,.DMMM ...MMMMM..... MMMMM..=MMM.....M MMM8...+MMM.8.....MMM8..DMMM8 .....MMMMN... MMMZ  ......MMMM.......    //
//    ...8MMM .....M MMMM... MMMMM. ... M MMM~..8MMM. .. M.MMMO...=MMM M... .MMMM...MMM.M..... MMMMM... MMMM N..... MMMM .....    //
//    ...MMM.IMO ..MMMMM .. MMMMM ..... . MMM...MMMM..... MMMM,....MMMM .....MMMM...MMM ?.......MMMMM ...MMMMD.  ZM+ MMM......    //
//    ... MMM=  .MMMMMM ...MMMMM ...... MMMMM...MMMM..... .MMM.....MMM  .... MMMM...MMMM8 ...... MMMMM ...MMMMMM ..+MMM ......    //
//    ....$MMMMMMMMMM~.....MMMM ........MMMM....MMMM.....=8MMM ....MMM?,: ...MMMM... MMMM.........MMMM ....,MMMMMMMMMM~ ......    //
//    ..... MMMMMMM  ..... MMM~.......,MMMM ....MMMN... ,.MMM......~MMM .... $MMM.....MMMM,....... MMM........MMMMMMM ........    //
//    .................... MMMM ..Z8 MMMMM,.....MMMM.... MMMM.......MMMM. ...MMMM......MMMMN $I. .MMMM........................    //
//    ..................... MMMMMMMMMMMMM. .....:MMMO.. MMMM ......  MMMM ..NMMMI.......MMMMMMMMMMMMM ........................    //
//    .......................MMMMMMMMMM:.........MMMMMMMMMM,..........MMMMMMMMMN ....... .MMMMMMMMMM  ........................    //
//    .........................DMMMMZ.............8MMMMMMM............ MMMMMMMN ............7MMMM8............................    //
//    .............................................. NM~.................~MM.,................................................    //
//    ........................................................................................................................    //
//    ........................................................................................................................    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract amddl is ERC1155Creator {
    constructor() ERC1155Creator() {}
}