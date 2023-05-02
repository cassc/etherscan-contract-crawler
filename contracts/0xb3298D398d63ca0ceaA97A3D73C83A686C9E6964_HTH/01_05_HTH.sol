// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: High The Horse
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//    High The Horse    //
//                      //
//                      //
//////////////////////////


contract HTH is ERC1155Creator {
    constructor() ERC1155Creator("High The Horse", "HTH") {}
}