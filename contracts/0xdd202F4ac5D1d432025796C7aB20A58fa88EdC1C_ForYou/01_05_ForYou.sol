// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: valentine
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    Happy Valentine's Day!    //
//                              //
//                              //
//////////////////////////////////


contract ForYou is ERC1155Creator {
    constructor() ERC1155Creator("valentine", "ForYou") {}
}