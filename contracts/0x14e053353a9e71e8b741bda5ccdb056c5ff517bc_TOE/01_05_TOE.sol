// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Too Open Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    69    //
//          //
//          //
//////////////


contract TOE is ERC721Creator {
    constructor() ERC721Creator("Too Open Edition", "TOE") {}
}