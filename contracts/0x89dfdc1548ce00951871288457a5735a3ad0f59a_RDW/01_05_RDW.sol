// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wonder
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    Wonder    //
//              //
//              //
//////////////////


contract RDW is ERC721Creator {
    constructor() ERC721Creator("Wonder", "RDW") {}
}