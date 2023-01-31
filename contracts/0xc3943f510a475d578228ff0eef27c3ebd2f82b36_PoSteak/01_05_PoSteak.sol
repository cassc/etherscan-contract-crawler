// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Proof of Steak
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                                                                //
//    At first, I created this room to participate in a fun game. Today, I want to share it to express my gratitude to the team and the community. All funds will be used to reinvest in the setter collection and purchase new setters. When 10 pieces of Proof of Steak are sold, one of the Proof of Steak holders will receive a real poser purchased from the floor. Winners will be chosen by Wild Cake!    //
//                                                                                                                                                                                                                                                                                                                                                                                                                //
//    I am vegetarian xD                                                                                                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PoSteak is ERC721Creator {
    constructor() ERC721Creator("Proof of Steak", "PoSteak") {}
}