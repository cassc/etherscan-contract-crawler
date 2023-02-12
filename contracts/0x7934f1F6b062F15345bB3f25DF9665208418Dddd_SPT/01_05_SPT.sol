// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sushi Pass Test
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    ////////    //
//                //
//                //
////////////////////


contract SPT is ERC721Creator {
    constructor() ERC721Creator("Sushi Pass Test", "SPT") {}
}