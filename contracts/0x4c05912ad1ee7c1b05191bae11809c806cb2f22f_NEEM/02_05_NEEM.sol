// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NEMOrld
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//     _______  ______________________   _____       //
//     \      \ \_   _____/\_   _____/  /     \      //
//     /   |   \ |    __)_  |    __)_  /  \ /  \     //
//    /    |    \|        \ |        \/    Y    \    //
//    \____|__  /_______  //_______  /\____|__  /    //
//            \/        \/         \/         \/     //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract NEEM is ERC721Creator {
    constructor() ERC721Creator("NEMOrld", "NEEM") {}
}