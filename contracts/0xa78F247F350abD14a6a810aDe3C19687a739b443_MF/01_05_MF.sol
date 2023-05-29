// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Meme Factory
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    Meme Factory - pepebyanon    //
//                                 //
//                                 //
/////////////////////////////////////


contract MF is ERC1155Creator {
    constructor() ERC1155Creator("Meme Factory", "MF") {}
}