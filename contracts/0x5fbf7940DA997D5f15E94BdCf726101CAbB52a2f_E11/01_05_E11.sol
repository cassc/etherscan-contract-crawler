// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 11:11 Editions { 2023 }
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    11:11 Editions { 2023 }    //
//                               //
//                               //
///////////////////////////////////


contract E11 is ERC721Creator {
    constructor() ERC721Creator("11:11 Editions { 2023 }", "E11") {}
}