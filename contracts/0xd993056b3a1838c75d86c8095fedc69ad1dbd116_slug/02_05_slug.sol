// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: made in world
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                   .. ..                                                    //
//                                                   ..MM$$$$OZZM.     .....                                  //
//                                                 .MZ$$ZMZ$$$$D8OMZ.:MM$Z$ZMN..                              //
//                                                8D$$$$$Z$MZ$ZNN8$ZZ$MMMNMMMD7I                              //
//                                              ZM$Z$$$$$$ZM .     .MOZZMM$8MM$$M.                            //
//                                            7MMD$$$$$$$$$M..     M.MM8$$OZ$MM$Z$M.                          //
//                                           ~M$$$$$$$$$$$Z$MM..  ?=MDM8IM..    MMM$N.                        //
//                                           MZ$$$$$$$$$$$Z$$ZMM, .MMMMM.      MMMMMM.                        //
//                                          MM$Z$$$$$$$$$$$$$$$$Z$$ZZ$ZZMM    .MMMMMNM                        //
//                                         IM$$$$$$$$$$$$$ZZO$Z$Z$Z$Z$$$ZZ$OMMMMMMMZD.                        //
//                                         M$$$$$$$$$$$$$$$M$$7$7$NMMMMMMMMMMDZZZZM.                          //
//                                       .MM$$$$$$$$$$$$Z$$$M$$8MMMMMMMMMD7$$$$$7$M.                          //
//                                       7MZ$Z$$$$$$$$$$ZMZ$$ZZMM$$$$$$$$$$$$$$7M$Z                           //
//                                      7M$Z$$$$$$$$$$$$$$ZZ$$$ZZZZ$8MMMMMMMMMM7$N.                           //
//                                     MM$$$$$$$$$$MZZ$$$$$$$$$$$$$$$$Z$$Z$$$$ZZM.                            //
//                                    8M$$$$$$$$ZMMZ$$$$$$$$$$$$$$$$$$$$$$$$$$$M                              //
//                                   .MZ$$$$$$ZMMZZ$$$$$$$$Z$Z$$$$$$$$$$$$$$$$$M                              //
//                                   DN$$$$$ZMMMZ$ZZZZ$ZZ$MMMMZ$$$$$$$$$$$$$$$$M                              //
//                                   IM$$$$$$$$OMMMMMMMMMMM$MOM$$$$$$MD$$$$$Z$MM                              //
//                                    MZ$$$$$$$$$$$$$$$ZZZ$$ZMMOZ$$$$$Z7MMMMMMZZ                              //
//                                     M$$$$$$Z$ZZZZZZ$ZZZ$$$MM$ZZ$$$$$$$$$$$$M.NM$ZND.                       //
//                                     M8MMMMMMMMMMMMMMMMMMZZZMMZ$$$$$$$$$$$ZMMN$Z$ZZ8..                      //
//                                    ZM$Z$$$$Z$$Z$$$$$$$ZZ$Z$Z$$$$$$$$$$$$$OMM$$$8MZ$D.                      //
//                                    MZ$$$ZZ$$$$$$$$Z$$$ZZ$$$$Z$$$$$$$$$$$$MMZ$$$$M$$M.                      //
//                                   MMZ$$$$$$$$$$$$$$$$$$$$$$$$$$$Z$$$$$$$MM$ZZZO$ZMMI.                      //
//                                  IM$$$$$$$$$$$$$$$$ZZZ$$$$$$$ZZ$$$ZZ$$$$MM$M. ..O. .                       //
//                                 MMDZ$$$$$$$$$$$$$Z$$ZZ$$$$$$Z$$$$$Z$$$$MN...                               //
//                                 MMZ$$$$$$$$$$$$$$$$$$MM$$$$$$$$Z$$$$$$MM.                                  //
//                                .MM$$$$$$$$$$$$$$$$$$$Z$MDZ$$$ZM$ZZ$ZZM8.                                   //
//                                 MZ$$$$$$$$$$$$$$$$$$$$$ZMMZZ$Z$Z$$ZMM                                      //
//                                 .M$$$$$$$$$$$$$$$$$$$$$$$$MM$$Z$$MM:.                                      //
//                                  .MMZZ$$$$$$$$$$$$$$$$$$$$$MMMMMM,.                                        //
//                                     .MMMMM$$$$$$$$$$$$$$$$$$$ZZM.                                          //
//                                 ....MM$$ZMM8$Z$$$$$$$$$$$$$$$$ZOM                                          //
//                             NMO$$$$$$$$$Z$$NMMZ$$$$$$$$$$$$$$MMMM,                                         //
//                            7M$$$$$$$$$$$$$$ZZMM$$$$$ZZZ$$$$$$M=.M.                                         //
//                            ,M$$$$$$$$$$$$$$$$$ZMDZ$$$$$$$$$$ZM.                                            //
//                             MZZ$$Z$$$$$$ZZ$ZZMMMMM$$$$$$$$$ZMM.                                            //
//                             M$$$$$M?MMMMMMMMO.   MMZ$$$$$$$MM                                              //
//                             MZ$$$$M               MZ$$$$$$MM..                                             //
//                             +M$$$$M               M$$$$$$$M+.                                              //
//                             .MMZ$$M              .MZ$$$$$MMMMMMM. .                                        //
//                               MM8M=.             MMZZ$$$$$Z$$$Z$MM                                         //
//                                                  MMZ$$$$ZZ$Z$$$$$$MI                                       //
//                                                  .MMMMMMMMMMMMMMMMD .                                      //
//                                                          .  .                                              //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract slug is ERC721Creator {
    constructor() ERC721Creator("made in world", "slug") {}
}