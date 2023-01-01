// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: World of Water
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    __          __   ____   __          __    //
//    \ \        / /  / __ \  \ \        / /    //
//     \ \  /\  / /  | |  | |  \ \  /\  / /     //
//      \ \/  \/ /   | |  | |   \ \/  \/ /      //
//       \  /\  /    | |__| |    \  /\  /       //
//        \/  \/      \____/      \/  \/        //
//                                              //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract WOW is ERC721Creator {
    constructor() ERC721Creator("World of Water", "WOW") {}
}