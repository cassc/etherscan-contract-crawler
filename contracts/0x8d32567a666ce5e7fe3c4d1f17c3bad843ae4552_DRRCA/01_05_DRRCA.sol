// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Dreaming Realm x Reddit Collectible Avatars
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    DREAMINGREALM    //
//                     //
//                     //
/////////////////////////


contract DRRCA is ERC721Creator {
    constructor() ERC721Creator("The Dreaming Realm x Reddit Collectible Avatars", "DRRCA") {}
}