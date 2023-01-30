// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Evan Shirley Art
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    🅴🆂🅷🅸🆁🅻🅴🆈🅰🆁🆃    //
//                              //
//                              //
//////////////////////////////////


contract ESA is ERC1155Creator {
    constructor() ERC1155Creator("Evan Shirley Art", "ESA") {}
}