// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Simpler Times
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    kjsouthernbelle    //
//                       //
//                       //
///////////////////////////


contract KJSB is ERC721Creator {
    constructor() ERC721Creator("Simpler Times", "KJSB") {}
}