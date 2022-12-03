// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: gm ccv2
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    gmccv2    //
//              //
//              //
//////////////////


contract gmccv2 is ERC721Creator {
    constructor() ERC721Creator("gm ccv2", "gmccv2") {}
}