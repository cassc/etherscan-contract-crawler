// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Your Beard Is Weird
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//    ___________                ___________.__          __________                        .___    //
//    \_   _____/___ _____ ______\__    ___/|  |__   ____\______   \ ____ _____ _______  __| _/    //
//     |    __)/ __ \\__  \\_  __ \|    |   |  |  \_/ __ \|    |  _// __ \\__  \\_  __ \/ __ |     //
//     |     \\  ___/ / __ \|  | \/|    |   |   Y  \  ___/|    |   \  ___/ / __ \|  | \/ /_/ |     //
//     \___  / \___  >____  /__|   |____|   |___|  /\___  >______  /\___  >____  /__|  \____ |     //
//         \/      \/     \/                     \/     \/       \/     \/     \/           \/     //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////


contract FTB is ERC721Creator {
    constructor() ERC721Creator("Your Beard Is Weird", "FTB") {}
}