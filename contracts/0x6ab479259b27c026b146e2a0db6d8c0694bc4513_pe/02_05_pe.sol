// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: polecon
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    test    //
//            //
//            //
////////////////


contract pe is ERC721Creator {
    constructor() ERC721Creator("polecon", "pe") {}
}