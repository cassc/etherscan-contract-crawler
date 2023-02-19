// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nude Is Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//     __    _ _     .       //
//     |\   |  |    /|       //
//     | \  |  |   /  \      //
//     |  \ |  |  /---'\     //
//     |   \|  /,'      \    //
//                           //
//                           //
//                           //
///////////////////////////////


contract NIA is ERC721Creator {
    constructor() ERC721Creator("Nude Is Art", "NIA") {}
}