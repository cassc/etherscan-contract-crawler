// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Feeling Blue
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Feeling Blue    //
//                    //
//                    //
////////////////////////


contract FB is ERC721Creator {
    constructor() ERC721Creator("Feeling Blue", "FB") {}
}