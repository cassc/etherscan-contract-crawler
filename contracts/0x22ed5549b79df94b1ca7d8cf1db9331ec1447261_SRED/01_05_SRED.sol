// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Saw Red
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//     _________                   //
//     /   _____/____ __  _  __    //
//     \_____  \\__  \\ \/ \/ /    //
//     /        \/ __ \\     /     //
//    /_______  (____  /\/\_/      //
//            \/     \/            //
//    __________           .___    //
//    \______   \ ____   __| _/    //
//     |       _// __ \ / __ |     //
//     |    |   \  ___// /_/ |     //
//     |____|_  /\___  >____ |     //
//            \/     \/     \/     //
//                                 //
//                                 //
/////////////////////////////////////


contract SRED is ERC1155Creator {
    constructor() ERC1155Creator("Saw Red", "SRED") {}
}