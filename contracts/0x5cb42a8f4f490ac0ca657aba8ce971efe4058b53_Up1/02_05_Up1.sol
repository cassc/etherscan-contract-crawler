// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Urban paintingz ERC 721 Single
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    urban.paintingz    //
//                       //
//                       //
///////////////////////////


contract Up1 is ERC721Creator {
    constructor() ERC721Creator("Urban paintingz ERC 721 Single", "Up1") {}
}