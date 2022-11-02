// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alice Official
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    Alice Official    //
//                      //
//                      //
//////////////////////////


contract ALICE is ERC721Creator {
    constructor() ERC721Creator("Alice Official", "ALICE") {}
}