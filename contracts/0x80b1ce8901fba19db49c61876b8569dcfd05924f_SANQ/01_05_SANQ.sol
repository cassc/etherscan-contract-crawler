// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sanqueira
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//                                                                  //
//       ___|                                    _)                 //
//     \___ \    _` |  __ \    _` |  |   |   _ \  |   __|  _` |     //
//           |  (   |  |   |  (   |  |   |   __/  |  |    (   |     //
//     _____/  \__,_| _|  _| \__, | \__,_| \___| _| _|   \__,_|     //
//                               _|                                 //
//                                                                  //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract SANQ is ERC721Creator {
    constructor() ERC721Creator("Sanqueira", "SANQ") {}
}