// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dogetrooper V3
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//    Dogetrooper V3    //
//                      //
//                      //
//////////////////////////


contract DogetrooperV3 is ERC1155Creator {
    constructor() ERC1155Creator("Dogetrooper V3", "DogetrooperV3") {}
}