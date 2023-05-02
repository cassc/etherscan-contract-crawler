// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kiwinator
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    Kiwi    //
//            //
//            //
////////////////


contract KIWI is ERC721Creator {
    constructor() ERC721Creator("Kiwinator", "KIWI") {}
}