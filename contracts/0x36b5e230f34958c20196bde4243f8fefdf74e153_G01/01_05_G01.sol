// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GELE 01
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    ░█▀▀░▄▀▄░▀█░    //
//    ░█░█░█/█░░█░    //
//    ░▀▀▀░░▀░░▀▀▀    //
//                    //
//                    //
////////////////////////


contract G01 is ERC721Creator {
    constructor() ERC721Creator("GELE 01", "G01") {}
}