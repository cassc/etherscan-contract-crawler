// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: gm ccv2 1155
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    gm    //
//          //
//          //
//////////////


contract gmccv21155 is ERC1155Creator {
    constructor() ERC1155Creator("gm ccv2 1155", "gmccv21155") {}
}