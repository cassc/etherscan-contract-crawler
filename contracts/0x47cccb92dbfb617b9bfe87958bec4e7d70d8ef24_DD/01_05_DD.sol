// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DeathDoor
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//    ________                 __  .__         //
//    \______ \   ____ _____ _/  |_|  |__      //
//     |    |  \_/ __ \\__  \\   __\  |  \     //
//     |    `   \  ___/ / __ \|  | |   Y  \    //
//    /_______  /\___  >____  /__| |___|  /    //
//            \/     \/     \/          \/     //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract DD is ERC721Creator {
    constructor() ERC721Creator("DeathDoor", "DD") {}
}