// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mfers in lowe's
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    __/\__    //
//    |    |    //
//              //
//              //
//////////////////


contract LOWES is ERC721Creator {
    constructor() ERC721Creator("mfers in lowe's", "LOWES") {}
}