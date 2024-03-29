// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WAGFI!!!
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                              //
//                                                                                                              //
//    __________                          .___    ________                 __          ____  __.      __        //
//    \______   \_____    ______ ____   __| _/    \______ \ _____    ____ |  | __     |    |/ _|____ |  | __    //
//     |    |  _/\__  \  /  ___// __ \ / __ |      |    |  \\__  \  /    \|  |/ /     |      <_/ __ \|  |/ /    //
//     |    |   \ / __ \_\___ \\  ___// /_/ |      |    `   \/ __ \|   |  \    <      |    |  \  ___/|    <     //
//     |______  /(____  /____  >\___  >____ |_____/_______  (____  /___|  /__|_ \_____|____|__ \___  >__|_ \    //
//            \/      \/     \/     \/     \/_____/       \/     \/     \/     \/_____/       \/   \/     \/    //
//                                                                                                              //
//                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WAGFI is ERC1155Creator {
    constructor() ERC1155Creator("WAGFI!!!", "WAGFI") {}
}