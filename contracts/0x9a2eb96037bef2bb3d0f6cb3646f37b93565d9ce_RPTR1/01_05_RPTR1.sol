// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Repeater 1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//    ______                      _                //
//    | ___ \                    | |               //
//    | |_/ /___ _ __   ___  __ _| |_ ___ _ __     //
//    |    // _ \ '_ \ / _ \/ _` | __/ _ \ '__|    //
//    | |\ \  __/ |_) |  __/ (_| | ||  __/ |       //
//    \_| \_\___| .__/ \___|\__,_|\__\___|_|       //
//              | |                                //
//              |_|                                //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract RPTR1 is ERC721Creator {
    constructor() ERC721Creator("Repeater 1", "RPTR1") {}
}