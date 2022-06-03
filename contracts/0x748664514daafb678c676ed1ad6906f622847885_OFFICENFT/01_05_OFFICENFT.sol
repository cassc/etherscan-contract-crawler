// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Office Magazine Covers
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    Covers    //
//              //
//              //
//////////////////


contract OFFICENFT is ERC721Creator {
    constructor() ERC721Creator("Office Magazine Covers", "OFFICENFT") {}
}