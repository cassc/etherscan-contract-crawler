// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SuerKawaiiArt
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//    SuperKawaii!!!    //
//                      //
//                      //
//////////////////////////


contract SKA is ERC1155Creator {
    constructor() ERC1155Creator("SuerKawaiiArt", "SKA") {}
}