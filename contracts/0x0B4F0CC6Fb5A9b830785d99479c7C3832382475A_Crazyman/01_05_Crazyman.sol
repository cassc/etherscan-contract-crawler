// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: crazyman
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//      ________________  ___________.__.    //
//    _/ ___\_  __ \__  \ \___   <   |  |    //
//    \  \___|  | \// __ \_/    / \___  |    //
//     \___  >__|  (____  /_____ \/ ____|    //
//         \/           \/      \/\/         //
//                                           //
//                                           //
///////////////////////////////////////////////


contract Crazyman is ERC721Creator {
    constructor() ERC721Creator("crazyman", "Crazyman") {}
}