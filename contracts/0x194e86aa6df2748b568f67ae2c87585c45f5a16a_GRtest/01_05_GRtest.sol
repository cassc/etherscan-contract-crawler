// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Grtest
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    test    //
//            //
//            //
////////////////


contract GRtest is ERC721Creator {
    constructor() ERC721Creator("Grtest", "GRtest") {}
}