// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hello World
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//                              //
//      ___ ___  __      __     //
//     /   |   \/  \    /  \    //
//    /    ~    \   \/\/   /    //
//    \    Y    /\        /     //
//     \___|_  /  \__/\  /      //
//           \/        \/       //
//                              //
//                              //
//                              //
//////////////////////////////////


contract HWN is ERC721Creator {
    constructor() ERC721Creator("Hello World", "HWN") {}
}