// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Night birds
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    Sebeth    //
//              //
//              //
//////////////////


contract SebEth is ERC721Creator {
    constructor() ERC721Creator("Night birds", "SebEth") {}
}