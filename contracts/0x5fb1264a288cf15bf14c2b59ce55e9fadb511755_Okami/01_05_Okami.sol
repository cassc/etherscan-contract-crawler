// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Okami
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//                                                        //
//      /$$$$$$  /$$                               /$$    //
//     /$$__  $$| $$                              |__/    //
//    | $$  \ $$| $$   /$$  /$$$$$$  /$$$$$$/$$$$  /$$    //
//    | $$  | $$| $$  /$$/ |____  $$| $$_  $$_  $$| $$    //
//    | $$  | $$| $$$$$$/   /$$$$$$$| $$ \ $$ \ $$| $$    //
//    | $$  | $$| $$_  $$  /$$__  $$| $$ | $$ | $$| $$    //
//    |  $$$$$$/| $$ \  $$|  $$$$$$$| $$ | $$ | $$| $$    //
//     \______/ |__/  \__/ \_______/|__/ |__/ |__/|__/    //
//                                                        //
//                                                        //
//                                                        //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract Okami is ERC721Creator {
    constructor() ERC721Creator("Okami", "Okami") {}
}