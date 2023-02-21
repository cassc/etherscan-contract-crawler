// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tristan Rettich
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Tristan Rettich 2023    //
//                            //
//                            //
////////////////////////////////


contract TR is ERC1155Creator {
    constructor() ERC1155Creator("Tristan Rettich", "TR") {}
}