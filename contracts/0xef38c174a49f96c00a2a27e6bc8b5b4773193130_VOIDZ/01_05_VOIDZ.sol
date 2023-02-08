// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Voidz
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    \/ () | |) ~/_     //
//                       //
//                       //
///////////////////////////


contract VOIDZ is ERC721Creator {
    constructor() ERC721Creator("Voidz", "VOIDZ") {}
}