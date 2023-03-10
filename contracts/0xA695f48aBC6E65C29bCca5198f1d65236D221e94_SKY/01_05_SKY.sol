// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sky Drops
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//    Sky City Drops    //
//                      //
//                      //
//////////////////////////


contract SKY is ERC1155Creator {
    constructor() ERC1155Creator("Sky Drops", "SKY") {}
}