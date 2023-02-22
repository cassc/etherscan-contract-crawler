// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GOLAND PASS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    GOLAND PASS    //
//                   //
//                   //
///////////////////////


contract GLD is ERC721Creator {
    constructor() ERC721Creator("GOLAND PASS", "GLD") {}
}