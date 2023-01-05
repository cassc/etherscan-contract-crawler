// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mutant Special Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    **Mutant Ape Special Edition**    //
//                                      //
//                                      //
//////////////////////////////////////////


contract MSE is ERC721Creator {
    constructor() ERC721Creator("Mutant Special Edition", "MSE") {}
}