// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GM in a bottle
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//    gm in a bottle    //
//                      //
//                      //
//////////////////////////


contract GM is ERC1155Creator {
    constructor() ERC1155Creator("GM in a bottle", "GM") {}
}