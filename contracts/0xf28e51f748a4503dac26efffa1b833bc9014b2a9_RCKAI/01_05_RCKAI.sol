// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rockwell AI Genesis Collection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                  __   ____   __                  //
//                 |  | |    | |  |                 //
//                 |  | |    | |  |                 //
//                 |  | |    | |  |                 //
//                 |  | |    | |  |                 //
//                 |  | |    | |  |                 //
//                 |  | |    | |  |                 //
//                 |  | |    | |  |                 //
//                 |  | |    | |  |                 //
//                 |  | |    | |  |                 //
//                 |  | |    | |  |                 //
//                /  /  |    |  \  \                //
//               /  /   |    |   \  \               //
//              /  /    |    |    \  \              //
//             /  /     |    |     \  \             //
//            /  /      |    |      \  \            //
//     _____ /  /       |    |       \  \______     //
//    |________/        |____|        \________|    //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract RCKAI is ERC721Creator {
    constructor() ERC721Creator("Rockwell AI Genesis Collection", "RCKAI") {}
}