// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GanWeaving
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//                                                                                //
//      ________              __      __                   .__                    //
//     /  _____/_____    ____/  \    /  \ ____ _____ ___  _|__| ____    ____      //
//    /   \  ___\__  \  /    \   \/\/   // __ \\__  \\  \/ /  |/    \  / ___\     //
//    \    \_\  \/ __ \|   |  \        /\  ___/ / __ \\   /|  |   |  \/ /_/  >    //
//     \______  (____  /___|  /\__/\  /  \___  >____  /\_/ |__|___|  /\___  /     //
//            \/     \/     \/      \/       \/     \/             \//_____/      //
//                                                                                //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////


contract GWEAV is ERC721Creator {
    constructor() ERC721Creator("GanWeaving", "GWEAV") {}
}