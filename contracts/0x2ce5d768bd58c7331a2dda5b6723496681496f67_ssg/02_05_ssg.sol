// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: sosogutter
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    ░▒▓█_its_art_█▓▒░    //
//                         //
//                         //
/////////////////////////////


contract ssg is ERC721Creator {
    constructor() ERC721Creator("sosogutter", "ssg") {}
}