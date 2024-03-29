// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BurnBabyBurn
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                //
//                                                                                                                                                                                //
//    __________                   __________       ___.          __________                      ___.             __  .__                          __            __  .__         //
//    \______   \__ _________  ____\______   \_____ \_ |__ ___.__.\______   \__ _________  ____   \_ |__ ___.__. _/  |_|  |__ _____    ____ _____ _/  |_    _____/  |_|  |__      //
//     |    |  _/  |  \_  __ \/    \|    |  _/\__  \ | __ <   |  | |    |  _/  |  \_  __ \/    \   | __ <   |  | \   __\  |  \\__  \  /    \\__  \\   __\ _/ __ \   __\  |  \     //
//     |    |   \  |  /|  | \/   |  \    |   \ / __ \| \_\ \___  | |    |   \  |  /|  | \/   |  \  | \_\ \___  |  |  | |   Y  \/ __ \|   |  \/ __ \|  |   \  ___/|  | |   Y  \    //
//     |______  /____/ |__|  |___|  /______  /(____  /___  / ____| |______  /____/ |__|  |___|  /  |___  / ____|  |__| |___|  (____  /___|  (____  /__| /\ \___  >__| |___|  /    //
//            \/                  \/       \/      \/    \/\/             \/                  \/       \/\/                 \/     \/     \/     \/     \/     \/          \/     //
//                                                                                                                                                                                //
//                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BurnBabyBurn is ERC721Creator {
    constructor() ERC721Creator("BurnBabyBurn", "BurnBabyBurn") {}
}