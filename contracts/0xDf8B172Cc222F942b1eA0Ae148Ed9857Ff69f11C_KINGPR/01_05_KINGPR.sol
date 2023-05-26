// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: King Peter Romulus
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

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


contract KINGPR is ERC721Creator {
    constructor() ERC721Creator("King Peter Romulus", "KINGPR") {}
}