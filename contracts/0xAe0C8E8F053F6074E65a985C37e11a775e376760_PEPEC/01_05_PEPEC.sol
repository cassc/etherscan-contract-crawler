// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PePe Commandments
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                    //
//                                                                                                                                    //
//    __________      __________         _________                                           .___                     __              //
//    \______   \ ____\______   \ ____   \_   ___ \  ____   _____   _____ _____    ____    __| _/_____   ____   _____/  |_  ______    //
//     |     ___// __ \|     ___// __ \  /    \  \/ /  _ \ /     \ /     \\__  \  /    \  / __ |/     \_/ __ \ /    \   __\/  ___/    //
//     |    |   \  ___/|    |   \  ___/  \     \___(  <_> )  Y Y  \  Y Y  \/ __ \|   |  \/ /_/ |  Y Y  \  ___/|   |  \  |  \___ \     //
//     |____|    \___  >____|    \___  >  \______  /\____/|__|_|  /__|_|  (____  /___|  /\____ |__|_|  /\___  >___|  /__| /____  >    //
//                   \/              \/          \/             \/      \/     \/     \/      \/     \/     \/     \/          \/     //
//                                                                                                                                    //
//                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PEPEC is ERC721Creator {
    constructor() ERC721Creator("PePe Commandments", "PEPEC") {}
}