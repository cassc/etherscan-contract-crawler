// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Legends
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//    .____                                    .___          //
//    |    |    ____   ____   ____   ____    __| _/______    //
//    |    |  _/ __ \ / ___\_/ __ \ /    \  / __ |/  ___/    //
//    |    |__\  ___// /_/  >  ___/|   |  \/ /_/ |\___ \     //
//    |_______ \___  >___  / \___  >___|  /\____ /____  >    //
//            \/   \/_____/      \/     \/      \/    \/     //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract Gratitude is ERC721Creator {
    constructor() ERC721Creator("Legends", "Gratitude") {}
}