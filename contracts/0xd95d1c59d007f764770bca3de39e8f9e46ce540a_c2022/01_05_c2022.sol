// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: McCormick®
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Luis Saucedo    //
//                    //
//                    //
////////////////////////


contract c2022 is ERC721Creator {
    constructor() ERC721Creator(unicode"McCormick®", "c2022") {}
}