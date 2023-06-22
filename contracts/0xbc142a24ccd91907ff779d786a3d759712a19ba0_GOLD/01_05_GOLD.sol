// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gilded
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//       ____   _   _       _              _     //
//      / ___| (_) | |   __| |   ___    __| |    //
//     | |  _  | | | |  / _` |  / _ \  / _` |    //
//     | |_| | | | | | | (_| | |  __/ | (_| |    //
//      \____| |_| |_|  \__,_|  \___|  \__,_|    //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract GOLD is ERC721Creator {
    constructor() ERC721Creator("Gilded", "GOLD") {}
}