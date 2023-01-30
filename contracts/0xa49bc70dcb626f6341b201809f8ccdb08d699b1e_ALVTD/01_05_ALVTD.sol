// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ALIENVTED Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//               .-.          //
//              /   \         //
//              |   |         //
//              |   |         //
//              |   |         //
//              \   /         //
//               `-'          //
//              /   \         //
//             /     \        //
//            /       \       //
//           /         \      //
//          /           \     //
//         /             \    //
//             /\_/\          //
//            / o o \         //
//           (   "   )        //
//           |   ^   |        //
//           | \___/ |        //
//           \_______/        //
//                            //
//                            //
////////////////////////////////


contract ALVTD is ERC721Creator {
    constructor() ERC721Creator("ALIENVTED Art", "ALVTD") {}
}