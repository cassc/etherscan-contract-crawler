// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Literal Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//           d8888 8888888b. 88888888888     //
//          d88888 888   Y88b    888         //
//         d88P888 888    888    888         //
//        d88P 888 888   d88P    888         //
//       d88P  888 8888888P"     888         //
//      d88P   888 888 T88b      888         //
//     d8888888888 888  T88b     888         //
//    d88P     888 888   T88b    888         //
//                                           //
//                                           //
//                                           //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract LiteralArt is ERC721Creator {
    constructor() ERC721Creator("Literal Art", "LiteralArt") {}
}