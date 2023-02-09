// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LateCheck Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    DDDDD   DDDDD   WW      WW IIIII NN   NN   GGGG      //
//    DD  DD  DD  DD  WW      WW  III  NNN  NN  GG  GG     //
//    DD   DD DD   DD WW   W  WW  III  NN N NN GG          //
//    DD   DD DD   DD  WW WWW WW  III  NN  NNN GG   GG     //
//    DDDDDD  DDDDDD    WW   WW  IIIII NN   NN  GGGGGG     //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract LCE is ERC1155Creator {
    constructor() ERC1155Creator("LateCheck Edition", "LCE") {}
}