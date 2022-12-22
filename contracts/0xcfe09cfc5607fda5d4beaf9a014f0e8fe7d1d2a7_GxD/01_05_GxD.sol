// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gifts x Dino
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//    Gifts x Dino    //
//                    //
//                    //
////////////////////////


contract GxD is ERC1155Creator {
    constructor() ERC1155Creator("Gifts x Dino", "GxD") {}
}