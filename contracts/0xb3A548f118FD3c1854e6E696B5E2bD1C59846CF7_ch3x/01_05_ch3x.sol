// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: chex
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    _________   ___ ___________ ____  ___    //
//    \_   ___ \ /   |   \_____  \\   \/  /    //
//    /    \  \//    ~    \_(__  < \     /     //
//    \     \___\    Y    /       \/     \     //
//     \______  /\___|_  /______  /___/\  \    //
//            \/       \/       \/      \_/    //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract ch3x is ERC721Creator {
    constructor() ERC721Creator("chex", "ch3x") {}
}