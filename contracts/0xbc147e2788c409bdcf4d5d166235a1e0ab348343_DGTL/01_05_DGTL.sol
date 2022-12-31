// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Digital World
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//            ____  ________     ____            //
//      _____/_   |/  _____/__ _/_   |_______    //
//     /     \|   /   __  \|  |  \   \___   /    //
//    |  Y Y  \   \  |__\  \  |  /   |/    /     //
//    |__|_|  /___|\_____  /____/|___/_____ \    //
//          \/           \/                \/    //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract DGTL is ERC1155Creator {
    constructor() ERC1155Creator("Digital World", "DGTL") {}
}