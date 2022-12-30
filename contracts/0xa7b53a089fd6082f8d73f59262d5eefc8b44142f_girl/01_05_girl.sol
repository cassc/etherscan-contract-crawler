// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Girl
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    071 105 114 108 115 013 010    //
//                                   //
//                                   //
///////////////////////////////////////


contract girl is ERC721Creator {
    constructor() ERC721Creator("Girl", "girl") {}
}