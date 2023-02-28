// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DIABLO
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                              //
//    ______ _____  ___  ______ _     _____     //
//    |  _  \_   _|/ _ \ | ___ \ |   |  _  |    //
//    | | | | | | / /_\ \| |_/ / |   | | | |    //
//    | | | | | | |  _  || ___ \ |   | | | |    //
//    | |/ / _| |_| | | || |_/ / |___\ \_/ /    //
//    |___/  \___/\_| |_/\____/\_____/\___/     //
//                                              //
//                                              //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract DIABLO is ERC721Creator {
    constructor() ERC721Creator("DIABLO", "DIABLO") {}
}