// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rare Pepe 3D
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//                                                       //
//                                                       //
//                                           ___   _     //
//     ___ ___ ___ ___    ___ ___ ___ ___   |_  |_| |    //
//    |  _| .'|  _| -_|  | . | -_| . | -_|  |_  | . |    //
//    |_| |__,|_| |___|  |  _|___|  _|___|  |___|___|    //
//                       |_|     |_|                     //
//                                                       //
//                                                       //
//                                                       //
//                                                       //
//                                                       //
//                                                       //
//                                                       //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract RP3D is ERC1155Creator {
    constructor() ERC1155Creator("Rare Pepe 3D", "RP3D") {}
}