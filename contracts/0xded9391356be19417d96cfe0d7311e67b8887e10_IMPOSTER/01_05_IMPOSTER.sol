// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 1mpo$ter
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//    ...11...MM.....MM.PPPPPPPP...OOOOOOO...$$$$$$$$..TTTTTTTT.EEEEEEEE.RRRRRRRR..    //
//    .1111...MMM...MMM.PP.....PP.OO.....OO.$$..$$..$$....TT....EE.......RR.....RR.    //
//    ...11...MMMM.MMMM.PP.....PP.OO.....OO.$$..$$........TT....EE.......RR.....RR.    //
//    ...11...MM.MMM.MM.PPPPPPPP..OO.....OO..$$$$$$$$.....TT....EEEEEE...RRRRRRRR..    //
//    ...11...MM.....MM.PP........OO.....OO.....$$..$$....TT....EE.......RR...RR...    //
//    ...11...MM.....MM.PP........OO.....OO.$$..$$..$$....TT....EE.......RR....RR..    //
//    .111111.MM.....MM.PP.........OOOOOOO...$$$$$$$$.....TT....EEEEEEEE.RR.....RR.    //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract IMPOSTER is ERC1155Creator {
    constructor() ERC1155Creator("1mpo$ter", "IMPOSTER") {}
}