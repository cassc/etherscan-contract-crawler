// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mea Culpa
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    This is an ASCII mark.    //
//                              //
//                              //
//////////////////////////////////


contract IFCKDUP is ERC721Creator {
    constructor() ERC721Creator("Mea Culpa", "IFCKDUP") {}
}