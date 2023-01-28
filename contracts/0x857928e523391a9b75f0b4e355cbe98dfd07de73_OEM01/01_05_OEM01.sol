// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OpepenEyes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//     +-+-+-+-+-+-+ +-+-+-+-+      //
//     |o|p|e|p|e|n| |e|y|e|s|      //
//     +-+-+-+-+-+-+-+-+-+-+-+      //
//     |b|y| |m|a|t|r|i|o|n|a|      //
//     +-+-+ +-+-+-+-+-+-+-+-+      //
//                                  //
//                                  //
//////////////////////////////////////


contract OEM01 is ERC1155Creator {
    constructor() ERC1155Creator("OpepenEyes", "OEM01") {}
}