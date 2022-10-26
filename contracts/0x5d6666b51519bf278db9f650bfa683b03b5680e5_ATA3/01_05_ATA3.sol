// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Andriy's Top Art 3
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                                               //
//     .d888888  d888888P  .d888888  d8888b.     //
//    d8'    88     88    d8'    88      `88     //
//    88aaaaa88a    88    88aaaaa88a  aaad8'     //
//    88     88     88    88     88      `88     //
//    88     88     88    88     88      .88     //
//    88     88     dP    88     88  d88888P     //
//                                               //
//                                               //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract ATA3 is ERC721Creator {
    constructor() ERC721Creator("Andriy's Top Art 3", "ATA3") {}
}