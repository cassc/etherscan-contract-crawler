// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Playtime Pepe
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    yuup    //
//            //
//            //
////////////////


contract PTP is ERC721Creator {
    constructor() ERC721Creator("Playtime Pepe", "PTP") {}
}