// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Spike AR
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//      _________      .__ __               _____ __________     //
//     /   _____/_____ |__|  | __ ____     /  _  \\______   \    //
//     \_____  \\____ \|  |  |/ // __ \   /  /_\  \|       _/    //
//     /        \  |_> >  |    <\  ___/  /    |    \    |   \    //
//    /_______  /   __/|__|__|_ \\___  > \____|__  /____|_  /    //
//            \/|__|           \/    \/          \/       \/     //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract SPAR is ERC721Creator {
    constructor() ERC721Creator("Spike AR", "SPAR") {}
}