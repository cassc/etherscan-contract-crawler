// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eth ERC721 editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    urban.paintingz    //
//                       //
//                       //
///////////////////////////


contract up1 is ERC721Creator {
    constructor() ERC721Creator("Eth ERC721 editions", "up1") {}
}