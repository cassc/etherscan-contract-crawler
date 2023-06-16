// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: All WRONG ALL RIGHT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    A series of oil paintings created by Krista Awad.     //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract AWAR is ERC721Creator {
    constructor() ERC721Creator("All WRONG ALL RIGHT", "AWAR") {}
}