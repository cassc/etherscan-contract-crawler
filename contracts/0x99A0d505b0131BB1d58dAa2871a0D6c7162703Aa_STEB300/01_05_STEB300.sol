// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: StartupToken Early Birds
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//                                                                                    //
//                                                                                    //
//     ____  _____  ____  ____  _____  _     ____  _____  ____  _  __ _____ _         //
//    / ___\/__ __\/  _ \/  __\/__ __\/ \ /\/  __\/__ __\/  _ \/ |/ //  __// \  /|    //
//    |    \  / \  | / \||  \/|  / \  | | |||  \/|  / \  | / \||   / |  \  | |\ ||    //
//    \___ |  | |  | |-|||    /  | |  | \_/||  __/  | |  | \_/||   \ |  /_ | | \||    //
//    \____/  \_/  \_/ \|\_/\_\  \_/  \____/\_/     \_/  \____/\_|\_\\____\\_/  \|    //
//     _____ ____  ____  _    ___  _   ____  _  ____  ____  ____                      //
//    /  __//  _ \/  __\/ \   \  \//  /  __\/ \/  __\/  _ \/ ___\                     //
//    |  \  | / \||  \/|| |    \  /   | | //| ||  \/|| | \||    \                     //
//    |  /_ | |-|||    /| |_/\ / /    | |_\\| ||    /| |_/|\___ |                     //
//    \____\\_/ \|\_/\_\\____//_/     \____/\_/\_/\_\\____/\____/                     //
//    _____  ____  ____                                                               //
//    \__  \/  _ \/  _ \                                                              //
//      /  || / \|| / \|                                                              //
//     _\  || \_/|| \_/|                                                              //
//    /____/\____/\____/                                                              //
//                                                                                    //
//                                                                                    //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////


contract STEB300 is ERC1155Creator {
    constructor() ERC1155Creator("StartupToken Early Birds", "STEB300") {}
}