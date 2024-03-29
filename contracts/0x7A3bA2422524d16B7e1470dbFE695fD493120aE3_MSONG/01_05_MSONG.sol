// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: a song of fragility and strength
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//                                             __    __                 _ _ _ _             //
//       __ _   ___  ___  _ __   __ _    ___  / _|  / _|_ __ __ _  __ _(_) (_) |_ _   _     //
//      / _` | / __|/ _ \| '_ \ / _` |  / _ \| |_  | |_| '__/ _` |/ _` | | | | __| | | |    //
//     | (_| | \__ \ (_) | | | | (_| | | (_) |  _| |  _| | | (_| | (_| | | | | |_| |_| |    //
//      \__,_| |___/\___/|_| |_|\__, |  \___/|_|   |_| |_|  \__,_|\__, |_|_|_|\__|\__, |    //
//                      _       |___/                    _   _    |___/           |___/     //
//       __ _ _ __   __| |  ___| |_ _ __ ___ _ __   __ _| |_| |__                           //
//      / _` | '_ \ / _` | / __| __| '__/ _ \ '_ \ / _` | __| '_ \   _____ _____ _____      //
//     | (_| | | | | (_| | \__ \ |_| | |  __/ | | | (_| | |_| | | | |_____|_____|_____|     //
//      \__,_|_| |_|\__,_| |___/\__|_|  \___|_| |_|\__, |\__|_| |_|                         //
//                                                 |___/                                    //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract MSONG is ERC721Creator {
    constructor() ERC721Creator("a song of fragility and strength", "MSONG") {}
}