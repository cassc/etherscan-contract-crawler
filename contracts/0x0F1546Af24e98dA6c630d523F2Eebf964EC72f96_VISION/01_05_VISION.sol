// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TRIP
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//      ___      _     _         _   _     //
//     / _ \    | |   | |       | \ | |    //
//    / /_\ \___| |__ | | ____ _|  \| |    //
//    |  _  / __| '_ \| |/ / _` | . ` |    //
//    | | | \__ \ | | |   < (_| | |\  |    //
//    \_| |_/___/_| |_|_|\_\__,_\_| \_/    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract VISION is ERC721Creator {
    constructor() ERC721Creator("TRIP", "VISION") {}
}