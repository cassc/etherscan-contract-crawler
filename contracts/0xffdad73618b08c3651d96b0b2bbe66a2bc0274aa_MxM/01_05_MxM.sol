// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Memes of the MEMES
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    S iz  th  m m s o  pro u tion      //
//      X  O   x  X O   X    O .         //
//      O  X   x  O X   O    X .         //
//      X  O   x  X O   X    O .         //
//      O  X   x  O X   O    X .         //
//      X  O   x  X O   .    O .         //
//      .  .   .  . .   .    X .         //
//                                       //
//        IF YOU KNOW YOU KNOW           //
//                                       //
//                                       //
///////////////////////////////////////////


contract MxM is ERC1155Creator {
    constructor() ERC1155Creator("Memes of the MEMES", "MxM") {}
}