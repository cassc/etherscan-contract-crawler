// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: climbing MEGA mountain
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//            /\                  //
//           /**\                 //
//          /****\   /\           //
//         /      \ /**\          //
//        /  /\    /    \         //
//       /  /  \  /      \        //
//      /  /    \/ /\     \       //
//     /  /      \/  \/\   \      //
//    /__/_______/___/__\___\     //
//                                //
//                                //
////////////////////////////////////


contract MTMEGA is ERC721Creator {
    constructor() ERC721Creator("climbing MEGA mountain", "MTMEGA") {}
}