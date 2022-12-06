// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RoyaltyTest2
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    RoyaltyTest2    //
//                    //
//                    //
////////////////////////


contract RT is ERC721Creator {
    constructor() ERC721Creator("RoyaltyTest2", "RT") {}
}