// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pink Sink
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//                                  //
//          ___         ___         //
//         /\  \       /\__\        //
//        /::\  \     /:/ _/_       //
//       /:/\:\__\   /:/ /\  \      //
//      /:/ /:/  /  /:/ /::\  \     //
//     /:/_/:/  /  /:/_/:/\:\__\    //
//     \:\/:/  /   \:\/:/ /:/  /    //
//      \::/__/     \::/ /:/  /     //
//       \:\  \      \/_/:/  /      //
//        \:\__\       /:/  /       //
//         \/__/       \/__/        //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract ps is ERC721Creator {
    constructor() ERC721Creator("Pink Sink", "ps") {}
}