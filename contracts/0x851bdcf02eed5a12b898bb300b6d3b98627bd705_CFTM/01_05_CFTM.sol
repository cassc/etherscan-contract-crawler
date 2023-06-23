// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Connected, for the Moment by Tyler Hobbs
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//     _         _                _           _     _             //
//    | |_ _   _| | ___ _ ____  _| |__   ___ | |__ | |__  ___     //
//    | __| | | | |/ _ \ '__\ \/ / '_ \ / _ \| '_ \| '_ \/ __|    //
//    | |_| |_| | |  __/ |   >  <| | | | (_) | |_) | |_) \__ \    //
//     \__|\__, |_|\___|_|  /_/\_\_| |_|\___/|_.__/|_.__/|___/    //
//         |___/                                                  //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract CFTM is ERC721Creator {
    constructor() ERC721Creator("Connected, for the Moment by Tyler Hobbs", "CFTM") {}
}