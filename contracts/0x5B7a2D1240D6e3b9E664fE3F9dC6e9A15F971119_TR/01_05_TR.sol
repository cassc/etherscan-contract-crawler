// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TRISTANRETTICH
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Tristan Rettich 2023    //
//                            //
//                            //
////////////////////////////////


contract TR is ERC721Creator {
    constructor() ERC721Creator("TRISTANRETTICH", "TR") {}
}