// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Visions of Paradise
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

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


contract VZN is ERC721Creator {
    constructor() ERC721Creator("Visions of Paradise", "VZN") {}
}