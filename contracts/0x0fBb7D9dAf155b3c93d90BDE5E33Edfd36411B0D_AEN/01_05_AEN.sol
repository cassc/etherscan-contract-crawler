// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alpha E. Neuman
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    mad x web3     //
//                   //
//                   //
///////////////////////


contract AEN is ERC721Creator {
    constructor() ERC721Creator("Alpha E. Neuman", "AEN") {}
}