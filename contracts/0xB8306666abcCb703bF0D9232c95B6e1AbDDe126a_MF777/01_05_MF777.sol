// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The First 777 Days
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                     //
//                                                                                                                     //
//    This initiative was created to do two important things;                                                          //
//                                                                                                                     //
//    1) Document my Journey as a creative, more specifically Photography.                                             //
//    2) Educate my collectors and connect with fellow crypto enthusiasts.                                             //
//                                                                                                                     //
//    Once the first 777 days are minted, I will be inscribing on Bitcoin's (BTC) Blockchain as Ordinals.              //
//                                                                                                                     //
//    I will take the time, 1-on-1, to teach you how to burn your ETH token & claim your BTC ord.                      //
//                                                                                                                     //
//    I will always be here to answer questions for all of my HODLers.                                                 //
//                                                                                                                     //
//    My overarching goal is to educate the masses to become more confident in operating on BTC & ETH blockchains.     //
//                                                                                                                     //
//    My underlying goal is to curb influencer manipulation through education.                                         //
//                                                                                                                     //
//    That's my commitment to this space.                                                                              //
//                                                                                                                     //
//    Join me on this Journey!                                                                                         //
//                                                                                                                     //
//    Yours Truly, Malo                                                                                                //
//                                                                                                                     //
//                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MF777 is ERC721Creator {
    constructor() ERC721Creator("The First 777 Days", "MF777") {}
}