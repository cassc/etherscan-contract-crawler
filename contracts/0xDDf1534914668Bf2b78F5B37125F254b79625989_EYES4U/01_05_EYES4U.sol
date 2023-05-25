// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EYES4U
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    EYES4U    //
//              //
//              //
//////////////////


contract EYES4U is ERC721Creator {
    constructor() ERC721Creator("EYES4U", "EYES4U") {}
}