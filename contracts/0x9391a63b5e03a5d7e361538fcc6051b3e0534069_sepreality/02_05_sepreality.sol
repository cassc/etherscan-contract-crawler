// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A separate reality
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//                                                        //
//                   .__     __               ___.        //
//      _____ _____  |  |___/  |______  _____ \_ |__      //
//     /     \\__  \ |  |  \   __\__  \ \__  \ | __ \     //
//    |  Y Y  \/ __ \|   Y  \  |  / __ \_/ __ \| \_\ \    //
//    |__|_|  (____  /___|  /__| (____  (____  /___  /    //
//          \/     \/     \/          \/     \/    \/     //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract sepreality is ERC721Creator {
    constructor() ERC721Creator("A separate reality", "sepreality") {}
}