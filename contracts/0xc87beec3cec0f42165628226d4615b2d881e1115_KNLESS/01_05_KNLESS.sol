// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nameless
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    ******* *******     //
//                        //
//                        //
////////////////////////////


contract KNLESS is ERC721Creator {
    constructor() ERC721Creator("Nameless", "KNLESS") {}
}