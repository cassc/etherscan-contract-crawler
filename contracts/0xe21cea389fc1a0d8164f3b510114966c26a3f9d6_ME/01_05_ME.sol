// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mememe
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////
//          //
//          //
//    ME    //
//          //
//          //
//////////////


contract ME is ERC721Creator {
    constructor() ERC721Creator("Mememe", "ME") {}
}