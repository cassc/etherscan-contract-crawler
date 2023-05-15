// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Modern love
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//    ____   ____________   .____      ___ ___     _____       //
//    \   \ /   /\_____  \  |    |    /   |   \   /  _  \      //
//     \   Y   /  /   |   \ |    |   /    ~    \ /  /_\  \     //
//      \     /  /    |    \|    |___\    Y    //    |    \    //
//       \___/   \_______  /|_______ \\___|_  / \____|__  /    //
//                       \/         \/      \/          \/     //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract Modern1 is ERC721Creator {
    constructor() ERC721Creator("Modern love", "Modern1") {}
}