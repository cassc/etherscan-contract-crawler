// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ad¥
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    ░█▀█░█▀▄░█░█    //
//    ░█▀█░█░█░░█░    //
//    ░▀░▀░▀▀░░░▀░    //
//                    //
//                    //
////////////////////////


contract ady is ERC721Creator {
    constructor() ERC721Creator(unicode"ad¥", "ady") {}
}