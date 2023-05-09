// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Reflections from Wonderland
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    HairofMedusa    //
//                    //
//                    //
////////////////////////


contract HOM is ERC721Creator {
    constructor() ERC721Creator("Reflections from Wonderland", "HOM") {}
}