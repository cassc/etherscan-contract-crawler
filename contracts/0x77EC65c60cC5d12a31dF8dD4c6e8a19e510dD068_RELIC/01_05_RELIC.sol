// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Relic: The Cabin
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//    __________  ___________ .____      .___  _________       //
//    \______   \ \_   _____/ |    |     |   | \_   ___ \      //
//     |       _/  |    __)_  |    |     |   | /    \  \/      //
//     |    |   \  |        \ |    |___  |   | \     \____     //
//     |____|_  / /_______  / |_______ \ |___|  \______  /     //
//            \/          \/          \/               \/      //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract RELIC is ERC1155Creator {
    constructor() ERC1155Creator("Relic: The Cabin", "RELIC") {}
}