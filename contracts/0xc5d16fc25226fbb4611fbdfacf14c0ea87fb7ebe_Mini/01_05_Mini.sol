// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Minimation
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Hello world!    //
//                    //
//                    //
////////////////////////


contract Mini is ERC721Creator {
    constructor() ERC721Creator("Minimation", "Mini") {}
}