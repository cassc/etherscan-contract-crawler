// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 3PEACE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    3peace    //
//              //
//              //
//////////////////


contract PEACE3 is ERC721Creator {
    constructor() ERC721Creator("3PEACE", "PEACE3") {}
}