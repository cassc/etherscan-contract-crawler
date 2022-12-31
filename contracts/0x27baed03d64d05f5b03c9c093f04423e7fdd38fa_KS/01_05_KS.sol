// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Korean Schooling
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//     █████   ████  █████████     //
//    ░░███   ███░  ███░░░░░███    //
//     ░███  ███   ░███    ░░░     //
//     ░███████    ░░█████████     //
//     ░███░░███    ░░░░░░░░███    //
//     ░███ ░░███   ███    ░███    //
//     █████ ░░████░░█████████     //
//    ░░░░░   ░░░░  ░░░░░░░░░      //
//                                 //
//                                 //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract KS is ERC721Creator {
    constructor() ERC721Creator("Korean Schooling", "KS") {}
}