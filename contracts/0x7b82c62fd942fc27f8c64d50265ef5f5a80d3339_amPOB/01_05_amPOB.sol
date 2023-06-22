// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: am POB
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllc;,,,,,,,,,;clllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllll;          .clllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllc,.......................;lllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllccc:.     .,;,,,,,,,;.      .:ccllllllllllllllllllllllllll    //
//    llllllllllllllllllllll;....'''''',,,,,,,,,,,''''''....clllllllllllllllllllllllll    //
//    lllllllllllllllllll:,,'. .',,,,,,,,,,,,,,,,,,,,,,,.. .,,;cllllllllllllllllllllll    //
//    lllllllllllllllllll'  .',,,,,,,,,,,,,,,,,,,,,,,,,,,,,.   ;llllllllllllllllllllll    //
//    lllllllllllllllc,......,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'......;lllllllllllllllllll    //
//    lllllllllllllcc:.  .,;,,,,,,,,,,,,,,,,,,,,',,,,,,,,,,,,;,.  .cccllllllllllllllll    //
//    llllllllllll;....'',,,,,,,.                       .,,,,,,'''....clllllllllllllll    //
//    llllllllllll;   .;,,,,,...             ...'.      .......,,,.  .:lllllllllllllll    //
//    llllllllllll,   .;,,,;.                ;kkOl.            .,,.  .:lllllllllllllll    //
//    llllllllllll,   .;,...       .:cccc;.  .,,;.   ,ccccc,   .,,.  .:lllllllllllllll    //
//    lllllllllccc,   .,,.         ;O0000k'         .o00000o.  .,,.  .;cccllllllllllll    //
//    lllllllll,....'',,,.  .ldl.  ;O0000x'  'ood:  .o00000o.  .;,,''....;llllllllllll    //
//    lllllllll.  .',,'.....:xOx.  'lllllc.  ;kkOl.  ;lllll:'.':ccccc:'.'cdodooollllll    //
//    lllllllll.  .';'.  ;kOOOOx.            ;kkOl.        'xOOOOOOOOOOOOOOOOOOxlcllll    //
//    llllllllc.  .';'.  ;kOOOOkl::::::::::::okOOxc:::::::::;;,;;;oOOOOOOOOOOOOkxxdoll    //
//    llllllccc.  .','   ,xxkOOOOOOOOkkkkOOOOOOOOOOOOOOkkkOl.     ;OOOOOOOOOOOOOOOkoll    //
//    lllllc....''.       ..;xOOOOOOOl..,dOOOOOOOOOOOOk:..:c.     ;OOOOOOOOOOOOOOOkoll    //
//    lllll:.  .,,.         .okxkOOOOo'.;xOOOdlllllllxk:..cc.     .clokOOOOOOOOOOOkoll    //
//    lllll:.  .,;.         .cloxOOOOOOkOOOOk;      .lOOOOOl.        'xOOOOOOOOOOOkoll    //
//    lllll:.  .,;.         .clldddkOOOOOOOOOdc:::::cxOOxdx:         .cll:,;oOOOOOkoll    //
//    lllll:.  .,;.         .cllllldkkkOOkkkkOOOOOOOOOOkdll;          ';'.  ;kOOOOkoll    //
//    lllll:.  .,,.         .clllllooooooooooooooooooooooll;          ';'   ;kOOOOkoll    //
//    lllll:.  .,;.         .cllllllllllll:;;;;;;;;;:clllll;         .';'   ;kOOOOkoll    //
//    lllll:.  .,;.         .clllllllllloc. ....... .;lllll;         .';'.  ;kOOOOkoll    //
//    lllllc;''.......      .oxdolllll:'.',,,,,,,,,,;clllll;       .......',lOOOOOkoll    //
//    lllllllll'  .';'.     .xOkdlllll;. .;olllllllllllllcc,      .,,.  .;lldOOOOOkoll    //
//    lllllllll.   ';'.     .xOOkkkdllc:::llllllllllllll,..    .''.  .;::clldOOOOOkoll    //
//    lllllllll,........    .xOOOOOxddl;,,;;;,,,,,,,,,,,.    ........'clc;,,:lllllc;,,    //
//    llllllllllll,   .,,.  .xOOOOOOOOl.                    ';'.  .cllll:.                //
//    llllllllllll,   .;,.  .xOOOOOOOOl.          ..............'':ll:'............       //
//    llllllolllll;   .;,.  .xOOOOOOOOl.         .',,,,,,,,.  .;lllll;   .;,,,,,,;'.      //
//    lloollllllll;   .;,.  .xOOOOOOOOl.     ..''.         .;::clllll;   .,,,,,,,,'       //
//    llllllllllll,   .;,.  .xOOOOOOOOl.     .,,;.         .:llllllll;   .;,,,,,,;'.      //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract amPOB is ERC1155Creator {
    constructor() ERC1155Creator("am POB", "amPOB") {}
}