// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Spring Gift 2023 from Doggygirl
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    -NFT--------------    //
//    -Doggygirl--------    //
//    --Doggygirl-------    //
//    ---Doggygirl------    //
//    ----Doggygirl-----    //
//    -----Doggygirl----    //
//    --------------NFT-    //
//                          //
//                          //
//////////////////////////////


contract DOGGY is ERC721Creator {
    constructor() ERC721Creator("Spring Gift 2023 from Doggygirl", "DOGGY") {}
}