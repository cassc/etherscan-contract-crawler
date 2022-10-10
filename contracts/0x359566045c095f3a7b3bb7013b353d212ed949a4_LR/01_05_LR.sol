// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: La Riviera
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    La Riviera    //
//                  //
//                  //
//////////////////////


contract LR is ERC721Creator {
    constructor() ERC721Creator("La Riviera", "LR") {}
}