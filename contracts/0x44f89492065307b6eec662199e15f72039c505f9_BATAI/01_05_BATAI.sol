// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Battle-of-AI
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//       ___       __  __  __      ___   ____    //
//      / _ )___ _/ /_/ /_/ /__   / _ | /  _/    //
//     / _  / _ `/ __/ __/ / -_) / __ |_/ /      //
//    /____/\_,_/\__/\__/_/\__/ /_/ |_/___/      //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract BATAI is ERC721Creator {
    constructor() ERC721Creator("Battle-of-AI", "BATAI") {}
}