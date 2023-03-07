// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: testing testing
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    test mint    //
//                 //
//                 //
/////////////////////


contract test23 is ERC721Creator {
    constructor() ERC721Creator("testing testing", "test23") {}
}