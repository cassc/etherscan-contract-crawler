// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Revise consumables
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////
//          //
//          //
//    RC    //
//          //
//          //
//////////////


contract RC is ERC721Creator {
    constructor() ERC721Creator("Revise consumables", "RC") {}
}