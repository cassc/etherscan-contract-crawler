// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Osipenkov
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//      _                        _    ____ _____     //
//     | |_ _ __ _   _  ___     / \  |  _ \_   _|    //
//     | __| '__| | | |/ _ \   / _ \ | |_) || |      //
//     | |_| |  | |_| |  __/  / ___ \|  _ < | |      //
//      \__|_|   \__,_|\___| /_/   \_\_| \_\|_|      //
//                                                   //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract tART is ERC721Creator {
    constructor() ERC721Creator("Osipenkov", "tART") {}
}