// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: King Romulus Kingdom
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//     ____  __.____________________     //
//    |    |/ _|\______   \______   \    //
//    |      <   |     ___/|       _/    //
//    |    |  \  |    |    |    |   \    //
//    |____|__ \ |____|    |____|_  /    //
//            \/                  \/     //
//                                       //
//                                       //
///////////////////////////////////////////


contract KPR is ERC1155Creator {
    constructor() ERC1155Creator("King Romulus Kingdom", "KPR") {}
}