// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: La Grande Famille de l'Art Contemporain
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    a1111ac011d0    //
//                    //
//                    //
////////////////////////


contract GFAC is ERC721Creator {
    constructor() ERC721Creator("La Grande Famille de l'Art Contemporain", "GFAC") {}
}