// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0xChecks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                              //
//                                                                                                              //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx      //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxxx      //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxx      //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkxdoooooooooooooooooooooooooooodxkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxx      //
//    xxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkko'............................'lkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxx      //
//    xxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkxdddc.                            .cdxxkOOOkkkkkkkkkkkkkkkxxxxxxxxxx      //
//    xxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkko'...                              ...'oOOOOOOOOkkkkkkkkkkkkxxxxxxxx      //
//    xxxxxxxxxxxxxxxxxxkkkkkkkkkkkxxxc.             0xProfessor              .cxkkkOOOOOOkkkkkkkkkkkkkxxxxx    //
//    xxxxxxxxxxxxxxxxkkkkkkkkkkkko,...                                      .'''lOOOOOOOOOkkkkkkkkkkkxxxx      //
//    xxxxxxxxxxxxxxxkkkkkkkkkkxxxc.                                            .:xkkkOOOOOOOkkkkkkkkkkkxx      //
//    xxxxxxxxxxxxxkkkkkkkkkkkl,''.       .;llllllllllllllllllllllllllll:.       .'''ckOOOOOOOOOkkkkkkkkkk      //
//    xxxxxxxxxxxxkkkkkkkkkkkk:..         .lxxxxxxxxxxxxxxxxxxxxxxxxxxxko.         ..;kOOOOOOOOOOkkkkkkkkk      //
//    xxxxxxxxxxkkkkkkkkkkkOOk:.      .;ccldxxxxxxxxxxxxxxxxxxxxxxxxxxxxxlcc:.     ..;k0OOOOOOOOOOOkkkkkkk      //
//    xxxxxxxxxkkkkkkkkkkkOOOk:.      .okxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd,     ..;k0OOOOOOOOOOOOkkkkkk      //
//    xxxxxxxxkkkkkkkkkkkOOOOk:.      .oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd,     ..;k000OOOOOOOOOOOkkkkk      //
//    xxxxxxxxkkkkkkkkkkOOOOOk:.      .oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd,     ..;k000000OOOOOOOOOkkkk      //
//    xxxxxxxkkkkkkkkkkOOkl;;;...     .oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd,     ...;::oO00OOOOOOOOOOkkk      //
//    xxxxxxkkkkkkkkkkkOOx;.          .oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd,       .  .,k000OOOOOOOOOOkk      //
//    xxxxxxkkkkkkkkkOOOOx,     .     .oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd,     ..    ,k00000OOOOOOOOOO      //
//    xxxxxxkkkkkkkkkOOOOx'           .oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd,           'x000000OOOOOOOOO      //
//    xxxxxkkkkkkkkkkOOOOx,           .,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;.           'x000000OOOOOOOOO      //
//    xxxxxkkkkkkkkkOOOOOx,     .                                                  .     'k0000000OOOOOOOO      //
//    xxxxxkkkkkkkkkOOOOOx,     .      .''.                  .''.                        ,k0000000OOOOOOOO      //
//    xxxxxkkkkkkkkkOOOOOx;.   ..     .oxxl.                'oxx:                  .     ;k00000000OOOOOOO      //
//    xxxxxkkkkkkkkkOOOOOkl,,,...     .oxxl.                'dxx:                   ..,,,lO000000000OOOOOO      //
//    xxxxxkkkkkkkkkOOOOOOOOOk:..     .oxxl.                'dxx:                   .;k0000000000000OOOOOO      //
//    xxxxxkkkkkkkkkOOOOOOOOOOl,''.   .oxxo,................;dxxl'...........    .'',lO0000000000000OOOOOO      //
//    xxxxxkkkkkkkkkOOOOOOOOOOOOOkc   .oxxxdddddddddddddddddxxxxxdddddddddddo'   ;kOO00000000000000OOOOOOO      //
//    xxxxxxkkkkkkkkOOOOOOOOOO0000c   .oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd,   :O0000000000000000OOOOOOO      //
//    xxxxxxkkkkkkkkkOOOOOOOOO0000c   .oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd,   :O0000000000000000OOOOOOO      //
//    xxxxxxkkkkkkkkkOOOOOOOOO0000c   .oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd,   :O000000000000000OOOOOOOO      //
//    xxxxxxxkkkkkkkkkOOOOOOOOO00Oc   .oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd,   :O00000000000000OOOOOOOOO      //
//    xxxxxxxkkkkkkkkkkOOOOOOOOO0Oc   .oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd,   :O00000000000000OOOOOOOOO      //
//    xxxxxxxxkkkkkkkkkOOOOOOOOOOOc   .oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd,   :O0000000000000OOOOOOOOOk      //
//    xxxxxxxxkkkkkkkkkkOOOOOOOOOOc   .oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd,   :O000000000000OOOOOOOOOOk      //
//    xxxxxxxxxkkkkkkkkkkkOOOOOOOOc   .oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd,   :O0000000000OOOOOOOOOOOkk      //
//    xxxxxxxxxxxkkkkkkkkkkOOOOOOOc   .oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd,   :O000000000OOOOOOOOOOOkkk      //
//    xxxxxxxxxxxxkkkkkkkkkkOOOOOOc   .oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd,   :O000000OOOOOOOOOOOOOkkkk      //
//    xxxxxxxxxxxxxkkkkkkkkkkkOOOOc   .oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd,   :O0000OOOOOOOOOOOOOkkkkkk      //
//    xxxxxxxxxxxxxxkkkkkkkkkkkkOOc   .oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:'',:ccldO0O0OOOOOOOOOOOOkkkkkkkk      //
//    xxxxxxxxxxxxxxxxkkkkkkkkkkkkc   .oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo.  .cO000OOOOOOOOOOOOOOkkkkkkkkkk      //
//    xxxxxxxxxxxxxxxxxxkkkkkkkkkkc   .oxxxxxxxxxxxxxxxl;,,,,,,,,,,,,,,,,:cccxOOOOOOOOOOOOOOOOkkkkkkkkkkkk      //
//    xxxxxxxxxxxxxxxxxxxkkkkkkkkkc   .oxxxxxxxxxxxxxkx,                .lOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkxx      //
//    xxxxxxxxxxxxxxxxxxxxxxkkkkkk:   .oxxxxxxxxxxxl;;;;;;;;;;;;;;;;;;;;:dOOOOOOOOOOOOOOOkkkkkkkkkkkkkkxxx      //
//    xxxxxxxxxxxxxxxxxxxxxxxkkkkk:   .oxxxxxxxxxxd,   ;xkOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkxxxxx      //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxkx:   .oxxxxxxxxxxd,   ;xkOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkxxxxxxxx      //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxx:   .oxxxxxxxxxxd,   ;xkOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkxxxxxxxxxx      //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxx:   .oxxxxxxxxxxd,   ;xxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxx      //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxx:   .oxxxxxxxxxxd,   ;dxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxx      //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxx:   .oxxxxxxxxxxd,   ;dxkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxx      //
//                                                                                                              //
//                             _+*THINK OUTSIDE THE BOX*+_                                                      //
//                                                                                                              //
//                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ZEROXCHECKS is ERC721Creator {
    constructor() ERC721Creator("0xChecks", "ZEROXCHECKS") {}
}