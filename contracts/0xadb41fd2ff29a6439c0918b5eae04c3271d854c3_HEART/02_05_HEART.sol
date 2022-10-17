// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HeartHouse
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Heart house.    //
//                    //
//                    //
////////////////////////


contract HEART is ERC721Creator {
    constructor() ERC721Creator("HeartHouse", "HEART") {}
}