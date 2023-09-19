// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EX3R
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    69 88 51 82     //
//                    //
//                    //
////////////////////////


contract EX3R is ERC721Creator {
    constructor() ERC721Creator("EX3R", "EX3R") {}
}