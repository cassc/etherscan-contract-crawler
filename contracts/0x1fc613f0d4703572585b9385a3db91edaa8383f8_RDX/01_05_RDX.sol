// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rare Dreams by 0xCroc
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    0xcroc 2023    //
//                   //
//                   //
///////////////////////


contract RDX is ERC721Creator {
    constructor() ERC721Creator("Rare Dreams by 0xCroc", "RDX") {}
}