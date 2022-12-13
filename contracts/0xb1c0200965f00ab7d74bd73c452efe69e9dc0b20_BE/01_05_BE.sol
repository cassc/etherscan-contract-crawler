// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bumpy Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    Bumpy Editions ~    //
//                        //
//                        //
////////////////////////////


contract BE is ERC1155Creator {
    constructor() ERC1155Creator("Bumpy Editions", "BE") {}
}