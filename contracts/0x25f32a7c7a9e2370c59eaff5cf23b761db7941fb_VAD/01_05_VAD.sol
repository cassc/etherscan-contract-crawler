// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Veilari Access Disk
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BMB---------------------B B    //
//    BBB---------------------BBB    //
//    BBB---------------------BBB    //
//    BBB---------------------BBB    //
//    BBB---------------------BBB    //
//    BBB---------------------BBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBB++++++++++++++++BBBBBB    //
//    BBBBB++BBBBB+++++++++BBBBBB    //
//    BBBBB++BBBBB+++++++++BBBBBB    //
//    BBBBB++BBBBB+++++++++BBBBBB    //
//    BBBBB++++++++++++++++BBBBBB    //
//                                   //
//                                   //
///////////////////////////////////////


contract VAD is ERC1155Creator {
    constructor() ERC1155Creator("Veilari Access Disk", "VAD") {}
}