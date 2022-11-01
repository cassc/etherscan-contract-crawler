// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HOLLYWOOD GAN GHOULS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    NNNNMdssssssssssssssssssssssssssssssssssssssNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNMdssssssssssssssssssssssssssssssssssssssNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMNN    //
//    NNNNMdssssssssssssssssssssssssssssssssssssssNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNMMdssssssssssssssssssssssssssssssssssssssNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMNN    //
//    NNNNMdssssssssssssssssssssssssssssssssssssssNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNMdssssssssssssssssssssssssssssssssssssssNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNMdssssssssssssssssssssssssssssssssssssssNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNMdssssssssssssssssssssssssssssssssssssssNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMNN    //
//    NNNNMdssssssssssssssssssssssssssssssssssssssmNNNNMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNmNNNNNNNNNMMNN    //
//    NNNMMdssssssssssssssssssssssssssssssssssssssmMNNNMMNNMdssyyyyyyyyyyyyyyssssyddddddddho:--+hddmmhMMNN    //
//    NNNMMdssssssssssssssssssssssssssssssssssssssmMMMMMMNMMdossssssssssssssssssssdddddddho/-`.-:sdddyMMNN    //
//    NNNMMdssssssssssssssssssssssssssssssssssssssmMMMMMNMMMdossssssssssssssssssssdddddddy-`:yyhhhdddyMMNN    //
//    NNNMMdssssssssssssssssssssssssssssssssssssssmMNMMMNMMMdsssssssssssssssssssssddddddhh//ohhhhhhhdyMMNN    //
//    NNNMMdssssssssssssssssssssssssssssssssssssssNMNNNMMMMMdsssssssssssssssssssssddddddhhhhshhhhhhhdyMMNN    //
//    NNNMMdyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyNMMNMMMMMMdsssssssssssssssssssssdddddddhhhshhhhhhhdyMMNN    //
//    NNNMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMNMMMMMMMdsssssssssssssssssssssddddddhhhhshhhhhhhdyMMMN    //
//    NNNNMMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMNNNNNNNMMMMMMMdsssssssssssssssssssssdddddhhyohshhhhhhhdyMMMN    //
//    NNNMMMMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMMMMMMMMNNMMMMMMMdsssssssssssssssssssssddddhhhs`//yhhhhhhdyMMMN    //
//    NNMMMmhhyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyhhhhhhmMMMMMMMMMdsssssssssssssssssssssddhhhhho `.shhhhhhhyMMMN    //
//    NNMMMdssoooooooooooooooooooooooooooooossssssmMMMMMMMMMdsssssssssssssssssssssddhhhhhy-``ohhhhhhhyMMMN    //
//    NMMMMdssooooooooooooooooooooooooooosssssssssmMMMMMMMMMdsssssssssssssssssssssddhhhhhhoos/shhhhhhyMMMN    //
//    NMMMMdssooooooooooooooooooooossoosssssssssssmMMMMMMMMMdsssssssssssssssssssssddhhhhhyyhhhhhhhhhhyMMMN    //
//    NMMMMdssooooossoooossssoooosssssssssssssssssmMMMMMMMMMdsssssssssssssssssssssddhhhhhyyhhhhhhhhhhyMMMN    //
//    NMMMMdsssooossssssssssssssssssssssssssssssssmMMMMMMMMMdsssssssssssssssssssssddhhhhhyhhhhhhhhhhhyMMMN    //
//    MMMMMdssssssssssssssssssssssssssssssssssssssmMMMMMMMMMdsssssssssssssssssssssddhhhhhyhhhhhhhhhhhyMMMN    //
//    MMMMMhssssssssssssssssssssssssssssssssssssssmMMMMMMMMMdsssssssssssssssssssssdhhhhhhshhhhhhhhhhhyMMMN    //
//    NMMMMhssosssssssssssssssssssssssssssssssssssmMMMMMMMMMdssssssssssssssssssssshhhhhhhyhhhhhhhhhhhyMMMN    //
//    NMMMMhssssssssssssssssssssssssssssssssssssssmMMMMMMMMMmyyyyyyyyyyyyyyyyyyyyhhhhhhhhyhhhhhhhhhhhhMMMN    //
//    MMMMMhsooossssssssssssssssssssssssssssssssssmMMMMMMMMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMMN    //
//    MMMMMhsooooossssssssssssssssssssssssssssssssmMMMMMMMMNNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNNNMMMMMMMN    //
//    MMMMMhssooooosssssssssssssssssssssssssssssssmMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN    //
//    NMMMMhsoosssssssssssssssssssssssssssssssssssmMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN    //
//    NMMMMhsoosssssssssssssssssssssssssssssssssssmMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMm    //
//    NMMMMhssssssssssssssssssssssssssssssssssssssmMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMm    //
//    dddddyhdhddddddddhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdddddddddddddddddddddddddddddN    //
//    yyyyyyNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNyyyyyyyyyyyyhhhhhhhhhhhhhhhhhhhhhyyyyyyyyyyyyyyyyyyyyhhm    //
//    yyyyyyNMMMMMMMMMMMMMMMNNNNNNMMMMMMMMMMMMMMMNyyyyyyyyyyhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhyyyyyyyyyyyyhyN    //
//    yyyyyyNMMMMMMMMMMMMMMMMMMNNMMMMMMMMMMMMMMMMNyyyyyyyyyyyhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhyyyyyyyyyyyyhym    //
//    yyyyyyNMMMMMMMMMMMMMMMMMNyhMMMMMMMMMMMMMMMMNyyyyyyyyyyyhhhhhhhhhhhhhhhhhhhhhhhhhhhhhyyyyyyyyyyyyyhhm    //
//    yyyyyyNMMMMMMMMMMMMMMMMMd.+MMMMMMMMMMMMMMMMNyyyyyyyyhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhyyyyyyyyyyyyyyyhhm    //
//    hhyyyyNMMMMMMMMMMMMMMMMMm-+MMMMMMMMMMMMMMMMNyyyyyyyhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhyyyyyyyyyyyyyyyyhhm    //
//    hhhhyyNMMMMMMMMMMMMMMMMMm-+MMMMMMMMMMMMMMMMNyyyyyyyhhhhhhhhhhhhhhhhhhhhhhhhhhhyyyyyyyyyyyyyyyyyyyhhm    //
//    hhhhhyNMMMMMMMMMMMMMMMMMm-+MMMMMMMMMMMMMMMMNyyyyyyyyyhyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyhhm    //
//    hhhhhyNMMMMMMMMMMMMMMMMMm-+MMMMMMMMMMMMMMMMNyyyyyyyhhhsyhhhhhhhhhhyhyyyyyyyyssssssssssssssssssssyyhm    //
//    hhhhhyNMMMMMMMMMMMMMMMMMm-+MMMMMMMMMMMMMMMMNyyyyyyyyhhshddddddddddddddddddddysssssssssssssssssssyyhm    //
//    hhhhyyNMMMMMMMMMMMMMMMMMm:+MMMMMMMMMMMMMMMMNyyyyyyyyyhyhddddddddddddddddddddysssssssssssssssssssyyhm    //
//    hhhyyyNMMMMMMMMMMMMMMMMMm:oMMMMMMMMMMMMMMMMNyyyyyyyyyhyhddddddddddddddddddddysssssssssssssssssssyyhm    //
//    hhyyyyNMMMMMMMMMMMMMMMMMm:oNMMMMMMMMMMMMMMMNyyyyyyyyyhyhddddddddddddddddddddysssssssssssssssssssyyhm    //
//    hhhhhyNMMMMMMMMMMMMMMMMMm:oNMMMMMMMMMMMMMMMNyyyyyyyyyhyhddddddddddddddddddddysssssssssssssssssssyyym    //
//    yyyyhyNMMMMMMMMMMMMMMMMMm/oNMMMMMMMMMMMMMMMNyyyyyyyyyhydddddddddddddddddddddysssssssssssssssssssyyym    //
//    hhhhhyNMMMMMMMMMMMMMMMMMm/oNMMMMMMMMMMMMMMMNyyyyyyhhhhydddddddddddddddddddddysssssssssssssssssssyyym    //
//    hhhhhymmmmmmmmmmmmmmmmmmd/ommmmmmmmmmmmmmmmmyyyhhhhhhhydddddddddddddddddddddysssssssssssssssssssyyym    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GHOUL is ERC721Creator {
    constructor() ERC721Creator("HOLLYWOOD GAN GHOULS", "GHOUL") {}
}