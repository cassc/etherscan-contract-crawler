// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Foundation Pass
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    ________      //
//    \_____  \     //
//      _(__  <     //
//     /       \    //
//    /______  /    //
//           \/     //
//                  //
//                  //
//////////////////////


contract FDN369 is ERC721Creator {
    constructor() ERC721Creator("Foundation Pass", "FDN369") {}
}