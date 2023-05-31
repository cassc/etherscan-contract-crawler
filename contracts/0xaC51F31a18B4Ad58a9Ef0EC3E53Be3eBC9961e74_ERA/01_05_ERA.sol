// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ERA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    _____________________    _____       //
//    \_   _____/\______   \  /  _  \      //
//     |    __)_  |       _/ /  /_\  \     //
//     |        \ |    |   \/    |    \    //
//    /_______  / |____|_  /\____|__  /    //
//            \/         \/         \/     //
//                                         //
//                                         //
/////////////////////////////////////////////


contract ERA is ERC721Creator {
    constructor() ERC721Creator("ERA", "ERA") {}
}