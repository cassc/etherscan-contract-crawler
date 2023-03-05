// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Notable
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//    o   o      o-o      o-O-o       O      o--o      o        o--o     //
//    |\  |     o   o       |        / \     |   |     |        |        //
//    | \ |     |   |       |       o---o    O--o      |        O-o      //
//    |  \|     o   o       |       |   |    |   |     |        |        //
//    o   o      o-o        o       o   o    o--o      O---o    o--o     //
//                                                                       //
//                                                                       //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract NOTBL is ERC721Creator {
    constructor() ERC721Creator("Notable", "NOTBL") {}
}