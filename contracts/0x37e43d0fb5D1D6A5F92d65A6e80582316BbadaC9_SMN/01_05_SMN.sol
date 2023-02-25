// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shaman
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    SHAMAN    //
//              //
//              //
//////////////////


contract SMN is ERC721Creator {
    constructor() ERC721Creator("Shaman", "SMN") {}
}