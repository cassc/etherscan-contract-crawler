// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: I Am Rich
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//       _____ ____ _____       //
//      /    /      \    \      //
//    /____ /_________\____\    //
//    \    \          /    /    //
//       \  \        /  /       //
//          \ \    / /          //
//            \ \/ /            //
//              \/              //
//                              //
//                              //
//////////////////////////////////


contract iamrich is ERC1155Creator {
    constructor() ERC1155Creator("I Am Rich", "iamrich") {}
}