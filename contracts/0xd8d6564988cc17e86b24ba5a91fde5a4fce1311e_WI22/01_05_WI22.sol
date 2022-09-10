// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wyplay IBC 2022
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//     __        __           _                 //
//     \ \      / /   _ _ __ | | __ _ _   _     //
//      \ \ /\ / / | | | '_ \| |/ _` | | | |    //
//       \ V  V /| |_| | |_) | | (_| | |_| |    //
//        \_/\_/  \__, | .__/|_|\__,_|\__, |    //
//                |___/|_|            |___/     //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract WI22 is ERC721Creator {
    constructor() ERC721Creator("Wyplay IBC 2022", "WI22") {}
}