// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ministry of Propaganda
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                              //
//                                              //
//     _______                       __         //
//    (   _   )                      \ \        //
//     | | | | __  ______ _  ____  __ \ \       //
//     | | | |/  \/ /  ._) |/ /  \/ /  > \      //
//     | | | ( ()  < () )|   < ()  <  / ^ \     //
//     |_| |_|\__/\_\__/ |_|\_\__/\_\/_/ \_\    //
//                                              //
//                                              //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract MIPRO is ERC721Creator {
    constructor() ERC721Creator("Ministry of Propaganda", "MIPRO") {}
}