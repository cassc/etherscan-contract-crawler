// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepefication
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//                    //
//    50 45 50 45     //
//                    //
//                    //
//                    //
////////////////////////


contract PEPE is ERC721Creator {
    constructor() ERC721Creator("Pepefication", "PEPE") {}
}