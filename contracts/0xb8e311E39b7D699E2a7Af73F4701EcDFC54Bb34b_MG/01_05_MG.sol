// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Magic Girl
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    Magic Girl    //
//                  //
//                  //
//////////////////////


contract MG is ERC721Creator {
    constructor() ERC721Creator("Magic Girl", "MG") {}
}