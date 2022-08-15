// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0xAbstracts by 0xMerc
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                   __  .__                    //
//    _____ ________/  |_|__| ____    ____      //
//    \__  \\_  __ \   __\  |/    \  / ___\     //
//     / __ \|  | \/|  | |  |   |  \/ /_/  >    //
//    (____  /__|   |__| |__|___|  /\___  /     //
//         \/                    \//_____/      //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract merc is ERC721Creator {
    constructor() ERC721Creator("0xAbstracts by 0xMerc", "merc") {}
}