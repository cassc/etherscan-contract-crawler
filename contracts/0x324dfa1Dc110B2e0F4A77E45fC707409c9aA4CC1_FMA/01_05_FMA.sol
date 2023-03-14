// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fritz Mead Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//     ____  _  _   __  __      //
//    (  __)( \/ ) / / / _\     //
//     ) _) / \/ \( ( /    \    //
//    (__)  \_)(_/ \_\\_/\_/    //
//                              //
//                              //
//////////////////////////////////


contract FMA is ERC721Creator {
    constructor() ERC721Creator("Fritz Mead Art", "FMA") {}
}