// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FR3AKS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//     _____ _____ ___ _____ _____ _____     //
//    |   __| __  |_  |  _  |  |  |   __|    //
//    |   __|    -|_  |     |    -|__   |    //
//    |__|  |__|__|___|__|__|__|__|_____|    //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract FR3K is ERC721Creator {
    constructor() ERC721Creator("FR3AKS", "FR3K") {}
}