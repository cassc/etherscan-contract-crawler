// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: gn
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    Created by Ballzerino 2023    //
//                                  //
//                                  //
//////////////////////////////////////


contract gn is ERC1155Creator {
    constructor() ERC1155Creator("gn", "gn") {}
}