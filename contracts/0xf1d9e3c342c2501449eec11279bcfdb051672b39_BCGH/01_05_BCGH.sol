// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bonjour Chaos
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//           .__                             //
//      ____ |  |__ _____    ____  ______    //
//    _/ ___\|  |  \\__  \  /  _ \/  ___/    //
//    \  \___|   Y  \/ __ \(  <_> )___ \     //
//     \___  >___|  (____  /\____/____  >    //
//         \/     \/     \/           \/     //
//                                           //
//                                           //
///////////////////////////////////////////////


contract BCGH is ERC1155Creator {
    constructor() ERC1155Creator("Bonjour Chaos", "BCGH") {}
}