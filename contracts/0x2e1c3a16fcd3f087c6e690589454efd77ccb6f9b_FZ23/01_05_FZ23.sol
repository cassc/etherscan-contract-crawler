// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Synesthetic
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    filipzaruba.com    //
//                       //
//                       //
///////////////////////////


contract FZ23 is ERC721Creator {
    constructor() ERC721Creator("Synesthetic", "FZ23") {}
}