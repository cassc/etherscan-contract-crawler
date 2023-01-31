// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nathan Head 1 of 1's
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//     _______    ___ ___  ____________  ____     //
//     \      \  /   |   \/_   \_____  \/_   |    //
//     /   |   \/    ~    \|   |/   |   \|   |    //
//    /    |    \    Y    /|   /    |    \   |    //
//    \____|__  /\___|_  / |___\_______  /___|    //
//            \/       \/              \/         //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract NH1O1 is ERC721Creator {
    constructor() ERC721Creator("Nathan Head 1 of 1's", "NH1O1") {}
}