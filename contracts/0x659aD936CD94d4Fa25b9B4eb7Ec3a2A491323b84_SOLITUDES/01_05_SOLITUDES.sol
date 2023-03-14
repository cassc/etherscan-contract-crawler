// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SOLITUDES
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    ADA OSSICA    //
//                  //
//                  //
//////////////////////


contract SOLITUDES is ERC721Creator {
    constructor() ERC721Creator("SOLITUDES", "SOLITUDES") {}
}