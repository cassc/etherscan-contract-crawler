// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GN TwitterStar
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    nadobroart    //
//                  //
//                  //
//////////////////////


contract GNTS is ERC1155Creator {
    constructor() ERC1155Creator("GN TwitterStar", "GNTS") {}
}