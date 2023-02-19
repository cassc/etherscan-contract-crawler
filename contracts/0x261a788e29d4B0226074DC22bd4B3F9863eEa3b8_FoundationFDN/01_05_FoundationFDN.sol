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
//                  //
//////////////////////


contract FoundationFDN is ERC721Creator {
    constructor() ERC721Creator("Foundation Pass", "FoundationFDN") {}
}