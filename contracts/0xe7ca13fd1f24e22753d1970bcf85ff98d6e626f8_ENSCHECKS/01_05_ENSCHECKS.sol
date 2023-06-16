// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ENS CHECKS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//                               //
//               __  .__         //
//         _____/  |_|  |__      //
//       _/ __ \   __\  |  \     //
//       \  ___/|  | |   Y  \    //
//     /\ \___  >__| |___|  /    //
//     \/     \/          \/     //
//                               //
//                               //
//                               //
///////////////////////////////////


contract ENSCHECKS is ERC721Creator {
    constructor() ERC721Creator("ENS CHECKS", "ENSCHECKS") {}
}