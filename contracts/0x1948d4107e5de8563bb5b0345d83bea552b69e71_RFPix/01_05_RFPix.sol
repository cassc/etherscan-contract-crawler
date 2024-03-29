// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RealFeetPix.wtf
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                             //
//                                                                                                             //
//    _________              .__  ___________            __ __________.__                     __    _____      //
//    \______   \ ____ _____  |  | \_   _____/___   _____/  |\______   \__|__  ___  __  _  ___/  |__/ ____\    //
//     |       _// __ \\__  \ |  |  |    __)/ __ \_/ __ \   __\     ___/  \  \/  /  \ \/ \/ /\   __\   __\     //
//     |    |   \  ___/ / __ \|  |__|     \\  ___/\  ___/|  | |    |   |  |>    <    \     /  |  |  |  |       //
//     |____|_  /\___  >____  /____/\___  / \___  >\___  >__| |____|   |__/__/\_ \ /\ \/\_/   |__|  |__|       //
//            \/     \/     \/          \/      \/     \/                       \/ \/                          //
//                                                                                                             //
//                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RFPix is ERC1155Creator {
    constructor() ERC1155Creator("RealFeetPix.wtf", "RFPix") {}
}