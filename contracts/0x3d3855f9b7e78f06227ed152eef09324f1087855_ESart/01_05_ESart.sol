// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Evan Shirley Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    🅴🆂🅷🅸🆁🅻🅴🆈🅰🆁🆃    //
//                              //
//                              //
//////////////////////////////////


contract ESart is ERC721Creator {
    constructor() ERC721Creator("Evan Shirley Art", "ESart") {}
}