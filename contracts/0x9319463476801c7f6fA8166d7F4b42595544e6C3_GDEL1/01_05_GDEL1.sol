// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Geoff Davis Micro Arts Group
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//     _____             __  __  ______            _         //
//    |  __ \           / _|/ _| |  _  \          (_)        //
//    | |  \/ ___  ___ | |_| |_  | | | |__ ___   ___ ___     //
//    | | __ / _ \/ _ \|  _|  _| | | | / _` \ \ / / / __|    //
//    | |_\ \  __/ (_) | | | |   | |/ / (_| |\ V /| \__ \    //
//     \____/\___|\___/|_| |_|   |___/ \__,_| \_/ |_|___/    //
//                                                           //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract GDEL1 is ERC721Creator {
    constructor() ERC721Creator("Geoff Davis Micro Arts Group", "GDEL1") {}
}