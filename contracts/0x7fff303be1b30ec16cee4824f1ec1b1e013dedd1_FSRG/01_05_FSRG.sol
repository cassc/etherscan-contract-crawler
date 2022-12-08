// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fifty Shades of Radiant glow
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//                                 //
//     _____ _____ _____ _____     //
//    |   __|   __| __  |   __|    //
//    |   __|__   |    -|  |  |    //
//    |__|  |_____|__|__|_____|    //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract FSRG is ERC1155Creator {
    constructor() ERC1155Creator("Fifty Shades of Radiant glow", "FSRG") {}
}