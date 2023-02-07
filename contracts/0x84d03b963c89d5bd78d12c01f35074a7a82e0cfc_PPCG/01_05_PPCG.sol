// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PEPE CHECK GAS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    made by notqventin.eth    //
//                              //
//                              //
//////////////////////////////////


contract PPCG is ERC1155Creator {
    constructor() ERC1155Creator("PEPE CHECK GAS", "PPCG") {}
}