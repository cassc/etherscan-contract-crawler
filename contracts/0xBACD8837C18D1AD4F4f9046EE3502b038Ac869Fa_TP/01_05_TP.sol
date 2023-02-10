// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Terrible Products
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    TERRIBLE    //
//                //
//                //
////////////////////


contract TP is ERC721Creator {
    constructor() ERC721Creator("Terrible Products", "TP") {}
}