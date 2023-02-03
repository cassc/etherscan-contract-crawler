// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks over Stripes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    Checks    //
//              //
//              //
//////////////////


contract CoS is ERC721Creator {
    constructor() ERC721Creator("Checks over Stripes", "CoS") {}
}