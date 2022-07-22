// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cosmic Rays
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM,MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMM 7MMMMMMMMMMMMMD.MMMMMMMMMMMMMMMI... ,MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMM7. MMMMMMMMMMMMM? MMMMMMMMMMMMMMMMMN MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM= =MMMMMMMMMMMMMMMMMMMMMMMMM+MMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMM .7MMMMMMMMMMMMMMMMM~MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM? DMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMM~.....NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMM  ......  NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM=MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMM$. .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMN .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMM.~MMMMMMMMMMMMMMMMMMMMD.. . . ...MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMI?MMMMMMMMMMMNMMMMMMMMMMMMMMMN    ...........   .~MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMN .~MMMMMMMMMMMMMMMMMMMMMMMM ....................... 7MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.MMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMM... MMMMMMMMMMMMMMMMMMMMMD .............................MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.. MMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMN .. ?MMMMMMMMMMMMMMMMMMN. ............................... MMMMMMMMMMMMMMMM. DMMMMMMMM+...NMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMN......MMMMMMMMMMMMMMMMM   D.M .....  MMMMMMOMMM7. ......... NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMM=....... . 8NMMMMMMMMMMM. M  D......OMMMMMMMMMMMMMMMN......... $MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM. MMMMMMMMMM    //
//    MMMMM . .............NMMMMMMMMM  M I. ....DMMMMMMMMMMMMMMMMMMMM ........+MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM7 .MMMMMMMMMM    //
//    MMMMD................MMMMMMMMM. M M....  MMMMMMMMMMMMMMMMMMMMMMM ........MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.    .:MMMMMMMM    //
//    MMMMMN . ........ ,MMMMMMMMMM  M D  .. IMMMMMMMMMMMMMMMMMMMMMMMMM,........MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM .MMMMMMMMMM    //
//    MMMMMMMMMD..... ZMMMMMMMMMMM .N D.....MMMMMMMMMMMMMMMMMMMMMMMMMMMM,....... MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM= MMMMMMMMMM    //
//    MMMMMMMMMMN ...,MMMMMMMMMMMD.. $,....DMMM8NMMMMMMMMMMMMMMMMMMMMMMMM........DMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMM ....MMMMMMMMMMM ........DMMMZ MMM.NMMMMMMMMMMMMMMMMMMMMI........MMMMMMMMMD.MMMMMMMMN.MMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMM$...NMMMMMMMMMMM....... .MMMM .MM  MMMMMMMMNMM. +: .. ~MM .......MMMMMMMM..  ~MMMMMMN .MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMM ..MMMMMMMMMMMM....... MMMM. MMN .NMMMMZ.. .........:NMMM.......MMMMMMMMMM.MMMMMMMMN. DMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMIMMMMMMMMMMMMO....... NMMM... ...........=N8. MMMM.DMMMM....DM NMMMMMMMMMMMMMMMMMM~...MMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMM7....... NMMN..MMM.. MMMN...NMMMMMMMMMMMMMM ...DM.NMMMMMMMMMMMMMMMMMD... MMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMM$....... 7MMM .MMMNN MDMMDDMMMMMMMMMMMMMMMM ...   MMMMMMMMMMMMMMMMMN  ... NMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMM.........MMMMMMMMMMMMM MMMMMMMMMM$MMN$MMMM....?..MMMMMMMMMMMMMMMM ..........MMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMM....... .MNMMMMMMM   .  .... ..   OMMMMMM,...N.$ MMMMMMMMMMMMMMN .......... MMMMMMMMMMMMMMMMM    //
//    MMMMMM?NMMMMMMMMMMMMMMMMMMM ...... ~D....?MMMMNMMMMMMMMMMNMMMMMMMMM=....7N DMMMMMMMMMMMMMM+......... .MMMMMMMMMMMMMMMMMM    //
//    MMMMM+ .MMMMMMMMMMMMMMMMMMMM...... .M......DMMMMMMMMMMMMMMNMMMMMMMMM .  7. MMMMMMMMMMMMMMMMM. ..... 8MMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMM. ......M.. .... MMMMMMMMMMMM .MMMMMMMMMM N Z MMMMMMMMMMMMMMMMMMMM  .. MMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMM. MMMMMMN ......IN ,. ....NMMMMMMMMN ...NMMMMMMNM?87.DMMMMMMMMM8MMMMMMMMMMM...8MMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.......,MI:.....     .........N....M..DM= =MMMMMMMMM  :MMMMMMMMMMN .MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM7........MM..............M....: . NM.. MMZMMMMMMMMMMMMMMMMMMMMMMMM +MMMMMMMMMMMN~MMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM....... M...............MNDN...ZMMM . DMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO  .MMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM ......ND...............   ...M$.MM.. ,MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM MMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMD  ..MMMM .......IOONMDMMMO MM..MMM. .NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM$..MMMMMZ ..... .NMMMMM$ MMMMMN:... .   ..MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMM .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN....... ..   MMMN  ...:MNN$.. .$MMMMMMMMMMMM..MMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.  ... . MMM....NN ... .,NMMMDMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM:MMMMMMMMMMMMMMN$+MNMMMN.. NMM..  :N........DMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM... NMMMMMMMMMMMMMMMMMMMIOMMMM ..MM. ...,..... .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.....  ..~MMMMMMMMMMMMMM M7.NN..~MN  .NMMMN......  NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM. ............... :ZO= ..... M..MMM. NMMMMMMM ..... N. MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN............................. MMMNMM NMMMMMMMMM.... D ...=MMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM  .............................. ,.. NMMMMMMMMMMMMMNOM8...... . ..MMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMI..............................................=MMMMMMMM  ............. MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMD ...................................................MMMMMMMM ............. NMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMM. .....................................................  MMMMMMMN,............. MMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMM..............................................................OMMMMMZ...............NMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMM. ................................................................DMMM.................7MMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMN...................................................................  NM ..................MMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMM ......................................................................  ....................MMMMMMMMMMMMMM    //
//    MMMMMMMMMMMM7...............................................................................................MMMMMMMMMMMM    //
//    MMMMMMMMMMMM................................................................................................ MMMMMMMMMMM    //
//    MMMMMMMMMMM. ................................................................................................ MMMMMMMMMM    //
//    MMMMMMMMMMD .................................................................................................. MMMMMMMMM    //
//    MMMMMMMMMM  ....................................................................................................MMMMMMMM    //
//    MMMMMMMMMM..................................................................................................... .MMMMMMM    //
//    MMMMMMMMM....................................................................................................... .MMMMMM    //
//    MMMMMMMM7.........................   .  .. . .....................................................................NMMMMM    //
//    MMMMMMMM ...................  ,DMMMMMMMMMMMMMM..........................  ....... ................. I .............MMMMM    //
//    MMMMMMM ........... ....NMMMNM:............. .M ........ .............DMM......MMM. ...............MO..............,MMMM    //
//    MMMMMMD........   .MMMMM.  MO .............  M+ ...... .MMMM.........NN.M .. MM .M.............. MM ................MMMM    //
//    MMMMMM.......,MMMMI.  .....M  ............+MM....... ZM8.MMM,......MM  NM .:MN..MD............ MM=..................NMMM    //
//    MMMMMM .....MM.  . .......MN........... NMN  ...... MM.7NZOM .....MM.. M,.NM. . M,..........?MM~. ..................OMMM    //
//    MMMMM,....................M.......   DMM= ....... ,M..MM  MM . .MM,....MMMO....NM.....   MMM8.......................OMMM    //
//    MMMMM ...................MM..... .MMM. ..........:M.MM, ..M:.?MM ......  ..... M... NMMN= ..........................NMMM    //
//    MMMM8 ...................M?...=MMN...............NMMI.... $MMN  ..............NMMMM8.  .............................NMMM    //
//    MMMM  ..................~M,NMM? ......................................  ..MMMMM ....................................MMMM    //
//    MMMM. ...............  NMMM .... . ...................................NMMM...M.....................................DMMMM    //
//    MMMM................MMMMMD8?==?DNDMMMMNZ. .........................MMN  ....MD.....................................MMMMM    //
//    MMMM...................ZM..............:MMMM, ..................+MM........MM......................................MMMMM    //
//    MMMM.................. M?.................. NM,............... MN  ...... MM......................................MMMMMM    //
//    MMMM..................~M..................... ...............8M..........MM.......................................MMMMMM    //
//    MMMM..................NN....................................,M .........MM...................................... MMMMMMM    //
//    MMMM................. M ....................................MI........ MM ...................................... MMMMMMM    //
//    MMMM................. 8 ....................................M:.......OM+........................................MMMMMMMM    //
//    MMMM........................................................$M.....NMM. ....................................... MMMMMMMM    //
//    MMMM.........................................................~MMMMMZ ..........................................DMMMMMMMM    //
//    MMMM...........................................................  ..............................................MMMMMMMMM    //
//    MMMM............................................................  ............................  ..............$MMMMMMMMM    //
//    MMMM......................................................................................................... MMMMMMMMMM    //
//    MMMM.........................................................................................................MMMMMMMMMMM    //
//    MMMM........................................................................................................ MMMMMMMMMMM    //
//    MMMM....................................................................................................... MMMMMMMMMMMM    //
//    MMMM..................................................................................................... .MMMMMMMMMMMMM    //
//    MMMM.................................................................................................... +MMMMMMMMMMMMMM    //
//    MMMM...................................................................................................ZMMMMMMMMMMMMMMMM    //
//    MMMM.............................................................. ............................. ....MMMMMMMMMMMMMMMMMMM    //
//    MMMM.............................................................................................. MMMMMMMMMMMMMMMMMMMMM    //
//    MMMM..............................................................................................MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMM...                                                         ..  .      .        .         ...MMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WWRAY is ERC721Creator {
    constructor() ERC721Creator("Cosmic Rays", "WWRAY") {}
}