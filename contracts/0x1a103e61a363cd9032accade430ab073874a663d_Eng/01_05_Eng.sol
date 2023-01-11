// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Engineers by Black Philip
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//         ___         //
//     ___/   \___     //
//    /   '---'   \    //
//    '--_______--'    //
//         / \         //
//        /   \        //
//        /\O/\        //
//        / | \        //
//        // \\        //
//                     //
//                     //
/////////////////////////


contract Eng is ERC721Creator {
    constructor() ERC721Creator("Engineers by Black Philip", "Eng") {}
}