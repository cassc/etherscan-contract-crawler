// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: gmeow
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//                                             //
//       __ _ _ __ ___   ___  _____      __    //
//      / _` | '_ ` _ \ / _ \/ _ \ \ /\ / /    //
//     | (_| | | | | | |  __/ (_) \ V  V /     //
//      \__, |_| |_| |_|\___|\___/ \_/\_/      //
//      |___/                                  //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract gmeow is ERC721Creator {
    constructor() ERC721Creator("gmeow", "gmeow") {}
}