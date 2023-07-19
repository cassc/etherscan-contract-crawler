// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Turbo Toad FC Shirts 2023
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//     ___    ___ ________         //
//    |\  \  /  /|\   ____\        //
//    \ \  \/  / | \  \___|        //
//     \ \    / / \ \  \  ___      //
//      /     \/   \ \  \|\  \     //
//     /  /\   \    \ \_______\    //
//    /__/ /\ __\    \|_______|    //
//    |__|/ \|__|                  //
//                                 //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract TTFC is ERC721Creator {
    constructor() ERC721Creator("Turbo Toad FC Shirts 2023", "TTFC") {}
}