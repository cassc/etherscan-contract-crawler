// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hazy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Keep it hazy    //
//                    //
//                    //
////////////////////////


contract hzy is ERC721Creator {
    constructor() ERC721Creator("Hazy", "hzy") {}
}