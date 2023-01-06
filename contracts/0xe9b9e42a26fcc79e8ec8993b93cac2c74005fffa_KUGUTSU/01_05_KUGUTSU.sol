// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NIKE AIRFORCE  1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                               //
//                                                                                               //
//    ██   ██ ██    ██  ██████  ██    ██ ████████ ███████ ██    ██                               //
//    ██  ██  ██    ██ ██       ██    ██    ██    ██      ██    ██                               //
//    █████   ██    ██ ██   ███ ██    ██    ██    ███████ ██    ██                               //
//    ██  ██  ██    ██ ██    ██ ██    ██    ██         ██ ██    ██                               //
//    ██   ██  ██████   ██████   ██████     ██    ███████  ██████                                //
//                                                                                               //
//    Absurd...                                                                                  //
//    Hideously beautiful and beautifully hideous...                                             //
//    Meat-tacular...                                                                            //
//    Nauseating...                                                                              //
//    Hilariously disgusting...                                                                  //
//    Captivating and repulsive...                                                               //
//    Meatalicius...NFT                                                                          //
//                                                                                               //
//    Decaying physical sculpture made with carefully selected materials (dead animal parts).    //
//    The original artwork will be dismembered and disposed of the remains.                      //
//                                                                                               //
//                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////


contract KUGUTSU is ERC721Creator {
    constructor() ERC721Creator("NIKE AIRFORCE  1", "KUGUTSU") {}
}