// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VXL
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    __      ____   ___          //
//    \ \    / /\ \ / / |         //
//     \ \  / /  \ V /| |         //
//      \ \/ /    > < | |         //
//       \  /    / . \| |____     //
//        \/    /_/ \_\______|    //
//                                //
//                                //
////////////////////////////////////


contract VXL is ERC721Creator {
    constructor() ERC721Creator("VXL", "VXL") {}
}