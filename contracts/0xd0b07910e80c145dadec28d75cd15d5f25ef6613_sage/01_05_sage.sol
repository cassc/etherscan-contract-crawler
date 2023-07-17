// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: sage
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    sage    //
//            //
//            //
////////////////


contract sage is ERC721Creator {
    constructor() ERC721Creator("sage", "sage") {}
}