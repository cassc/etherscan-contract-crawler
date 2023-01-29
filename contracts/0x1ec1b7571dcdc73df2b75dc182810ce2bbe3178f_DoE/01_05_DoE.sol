// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Days of Exploration
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//                         //
//     ____   __  ____     //
//    (    \ /  \(  __)    //
//     ) D ((  O )) _)     //
//    (____/ \__/(____)    //
//                         //
//                         //
//                         //
/////////////////////////////


contract DoE is ERC721Creator {
    constructor() ERC721Creator("Days of Exploration", "DoE") {}
}