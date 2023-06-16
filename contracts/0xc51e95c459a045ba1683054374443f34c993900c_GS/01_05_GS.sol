// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Generative Space
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    Generative art, only 100% code, p5.js    //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract GS is ERC721Creator {
    constructor() ERC721Creator("Generative Space", "GS") {}
}