// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NOT YOUR KEYS NOT YOUR COINS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//    NOT YOUR KEYS NOT YOUR COINS                                        //
//    GLITCH VESRION                                                      //
//                                                                        //
//    Check Everything, Save Your Keys ! Come and take it “ Your Keys”    //
//    1/1 - 2000 x 2502 px                                                //
//                                                                        //
//    Inspired and respect to :                                           //
//    Vincent Van Dough                                                   //
//    Jack Butcher                                                        //
//    Domino Pepe inspiration from:                                       //
//    Geometric Pepe from Batz                                            //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract KEYSCOINS is ERC721Creator {
    constructor() ERC721Creator("NOT YOUR KEYS NOT YOUR COINS", "KEYSCOINS") {}
}