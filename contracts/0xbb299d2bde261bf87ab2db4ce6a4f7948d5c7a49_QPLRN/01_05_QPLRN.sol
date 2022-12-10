// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: QP Learns Photography
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//                _                                    //
//     ___ ___   | |___ ___ ___ ___ ___                //
//    | . | . |  | | -_| .'|  _|   |_ -|               //
//    |_  |  _|  |_|___|__,|_| |_|_|___|               //
//      |_|_|      _                       _           //
//     ___| |_ ___| |_ ___ ___ ___ ___ ___| |_ _ _     //
//    | . |   | . |  _| . | . |  _| .'| . |   | | |    //
//    |  _|_|_|___|_| |___|_  |_| |__,|  _|_|_|_  |    //
//    |_|                 |___|       |_|     |___|    //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract QPLRN is ERC721Creator {
    constructor() ERC721Creator("QP Learns Photography", "QPLRN") {}
}