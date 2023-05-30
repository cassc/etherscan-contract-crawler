// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hint of Mint Airdrops
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//                                                             //
//      _   _ _       _            __   __  __ _       _       //
//     | | | (_)_ __ | |_    ___  / _| |  \/  (_)_ __ | |_     //
//     | |_| | | '_ \| __|  / _ \| |_  | |\/| | | '_ \| __|    //
//     |  _  | | | | | |_  | (_) |  _| | |  | | | | | | |_     //
//     |_| |_|_|_| |_|\__|  \___/|_|   |_|  |_|_|_| |_|\__|    //
//                                                             //
//                                                             //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract HoMA is ERC1155Creator {
    constructor() ERC1155Creator("Hint of Mint Airdrops", "HoMA") {}
}