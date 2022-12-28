// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aestrild
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//                                       .     .     //
//                        /       .-.   /     /      //
//      .-.    .-.  . ---/---).--.`-'  / .-../       //
//     (  |  ./.-'_/ \  /   /    /    / (   /        //
//      `-'-'(__.'/ ._)/   /  _.(__._/_.-`-'-..      //
//               /                                   //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract AES is ERC721Creator {
    constructor() ERC721Creator("Aestrild", "AES") {}
}