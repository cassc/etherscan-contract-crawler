// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: pepe
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    pepe pepe    //
//                 //
//                 //
/////////////////////


contract pep is ERC721Creator {
    constructor() ERC721Creator("pepe", "pep") {}
}