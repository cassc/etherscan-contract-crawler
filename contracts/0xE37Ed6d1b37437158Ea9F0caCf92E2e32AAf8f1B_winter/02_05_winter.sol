// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Winter
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//                           //
//    ____    __    ____     //
//    \   \  /  \  /   /     //
//     \   \/    \/   /      //
//      \            /       //
//       \    /\    /        //
//        \__/  \__/         //
//                           //
//                           //
//                           //
//                           //
///////////////////////////////


contract winter is ERC721Creator {
    constructor() ERC721Creator("Winter", "winter") {}
}