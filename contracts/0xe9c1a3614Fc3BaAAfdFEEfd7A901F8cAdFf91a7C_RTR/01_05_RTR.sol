// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GRT Tracks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//      ________        __                               __  .__         //
//     /  _____/_______/  |_  ____   ____   ____ _______/  |_|  |__      //
//    /   \  __\_  __ \   __\/ __ \ /    \ /  _ \\____ \   __\  |  \     //
//    \    \_\  \  | \/|  | \  ___/|   |  (  <_> )  |_> >  | |   Y  \    //
//     \______  /__|   |__|  \___  >___|  /\____/|   __/|__| |___|  /    //
//            \/                 \/     \/       |__|             \/     //
//      ___________                     __                               //
//      \__    ___/___________    ____ |  | __  ______                   //
//        |    |  \_  __ \__  \ _/ ___\|  |/ / /  ___/                   //
//        |    |   |  | \// __ \\  \___|    <  \___ \                    //
//        |____|   |__|  (____  /\___  >__|_ \/____  >                   //
//                            \/     \/     \/     \/                    //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract RTR is ERC721Creator {
    constructor() ERC721Creator("GRT Tracks", "RTR") {}
}