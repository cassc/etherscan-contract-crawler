// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test420420
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    test mark    //
//                 //
//                 //
/////////////////////


contract Test420 is ERC721Creator {
    constructor() ERC721Creator("Test420420", "Test420") {}
}