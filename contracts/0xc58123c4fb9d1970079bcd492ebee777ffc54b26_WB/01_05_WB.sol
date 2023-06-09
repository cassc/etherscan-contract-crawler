// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Woodland Beasts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//            /\_/\      //
//       ___ / o o \     //
//     /'___(     )      //
//    (___/ \___/        //
//                       //
//                       //
///////////////////////////


contract WB is ERC721Creator {
    constructor() ERC721Creator("Woodland Beasts", "WB") {}
}