// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Burn Test
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//         _          //
//       _| |         //
//     _| | |         //
//    | | | |         //
//    | | | | __      //
//    | | | |/  \     //
//    |       /\ \    //
//    |      /  \/    //
//    |      \  /\    //
//    |       \/ /    //
//     \        /     //
//      |     /       //
//      |    |        //
//                    //
//                    //
////////////////////////


contract BURN is ERC721Creator {
    constructor() ERC721Creator("Burn Test", "BURN") {}
}