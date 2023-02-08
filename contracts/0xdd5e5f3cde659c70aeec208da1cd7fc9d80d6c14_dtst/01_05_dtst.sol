// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: dogtest
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    -----`````----    //
//                      //
//                      //
//////////////////////////


contract dtst is ERC721Creator {
    constructor() ERC721Creator("dogtest", "dtst") {}
}