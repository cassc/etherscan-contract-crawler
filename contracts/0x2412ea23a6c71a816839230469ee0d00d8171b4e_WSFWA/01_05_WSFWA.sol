// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rise ∞ Fall by Wildalps
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Wolf Society    //
//    Rise ∞ Fall     //
//    by Wildalps     //
//                    //
//                    //
////////////////////////


contract WSFWA is ERC721Creator {
    constructor() ERC721Creator(unicode"Rise ∞ Fall by Wildalps", "WSFWA") {}
}