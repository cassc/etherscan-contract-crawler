// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: signal propagation
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//    dove was here.    //
//                      //
//                      //
//////////////////////////


contract sgp is ERC1155Creator {
    constructor() ERC1155Creator("signal propagation", "sgp") {}
}