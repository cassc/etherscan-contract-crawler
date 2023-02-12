// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RIXEL ART
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//      _____  _______   ________ _          //
//     |  __ \|_   _\ \ / /  ____| |         //
//     | |__) | | |  \ V /| |__  | |         //
//     |  _  /  | |   > < |  __| | |         //
//     | | \ \ _| |_ / . \| |____| |____     //
//     |_|  \_\_____/_/ \_\______|______|    //
//                                           //
//                                           //
///////////////////////////////////////////////


contract RX is ERC721Creator {
    constructor() ERC721Creator("RIXEL ART", "RX") {}
}