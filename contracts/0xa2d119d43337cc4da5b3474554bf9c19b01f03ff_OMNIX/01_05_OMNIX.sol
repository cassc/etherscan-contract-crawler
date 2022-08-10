// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Omni X
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    ________                 .__  ____  ___    //
//    \_____  \   _____   ____ |__| \   \/  /    //
//     /   |   \ /     \ /    \|  |  \     /     //
//    /    |    \  Y Y  \   |  \  |  /     \     //
//    \_______  /__|_|  /___|  /__| /___/\  \    //
//            \/      \/     \/           \_/    //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract OMNIX is ERC721Creator {
    constructor() ERC721Creator("Omni X", "OMNIX") {}
}