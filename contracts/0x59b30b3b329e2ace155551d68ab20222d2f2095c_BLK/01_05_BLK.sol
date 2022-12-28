// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Painted Black
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Painted Black    //
//                     //
//                     //
/////////////////////////


contract BLK is ERC721Creator {
    constructor() ERC721Creator("Painted Black", "BLK") {}
}