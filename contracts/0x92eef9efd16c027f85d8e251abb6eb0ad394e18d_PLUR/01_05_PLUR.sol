// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FTR: For the Rave!
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
//    ___________              __  .__             __________                   ._.                  //
//    \_   _____/__________  _/  |_|  |__   ____   \______   \_____ ___  __ ____| |                  //
//     |    __)/  _ \_  __ \ \   __\  |  \_/ __ \   |       _/\__  \\  \/ // __ \ |                  //
//     |     \(  <_> )  | \/  |  | |   Y  \  ___/   |    |   \ / __ \\   /\  ___/\|                  //
//     \___  / \____/|__|     |__| |___|  /\___  >  |____|_  /(____  /\_/  \___  >_                  //
//         \/                           \/     \/          \/      \/          \/\/                  //
//                                                                                                   //
//    "For the Rave" is an animated AI series exploring the rave culture's excitement and energy.    //
//    The series is driven by the fundamental PLUR (Peace, Love, Unity, and Respect)                 //
//    values that define the rave community and provide a colorful and immersive experience          //
//    for viewers. Through its high-octane narrative, the series takes audiences on a                //
//    journey through the world of raving and its electrifying atmosphere, culminating in a          //
//    celebration of peace, love unity, and respect.                                                 //
//                                                                                                   //
//                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////


contract PLUR is ERC1155Creator {
    constructor() ERC1155Creator("FTR: For the Rave!", "PLUR") {}
}