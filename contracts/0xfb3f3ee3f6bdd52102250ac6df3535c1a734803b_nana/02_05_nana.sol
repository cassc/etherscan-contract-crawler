// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Banana
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    Banana    //
//              //
//              //
//////////////////


contract nana is ERC721Creator {
    constructor() ERC721Creator("Banana", "nana") {}
}