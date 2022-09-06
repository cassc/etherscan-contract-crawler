// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Zien
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    AZSC    //
//            //
//            //
////////////////


contract AZSC is ERC721Creator {
    constructor() ERC721Creator("Zien", "AZSC") {}
}