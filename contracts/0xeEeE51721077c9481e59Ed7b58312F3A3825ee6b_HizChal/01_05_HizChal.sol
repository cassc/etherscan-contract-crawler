// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hizzys Challenger
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//                                                               //
//      ___ ___ .__       _________ .__           .__  .__       //
//     /   |   \|__|______\_   ___ \|  |__ _____  |  | |  |      //
//    /    ~    \  \___   /    \  \/|  |  \\__  \ |  | |  |      //
//    \    Y    /  |/    /\     \___|   Y  \/ __ \|  |_|  |__    //
//     \___|_  /|__/_____ \\______  /___|  (____  /____/____/    //
//           \/          \/       \/     \/     \/               //
//                                                               //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract HizChal is ERC721Creator {
    constructor() ERC721Creator("Hizzys Challenger", "HizChal") {}
}