// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Momo Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//     ,__ __    __   ,__ __    __      ,__ __       //
//    /|  |  |  /\_\//|  |  |  /\_\/ ()/|  |  |      //
//     |  |  | |    | |  |  | |    | /\ |  |  |      //
//     |  |  | |    | |  |  | |    |/  \|  |  |      //
//     |  |  |_/\__/  |  |  |_/\__//(__/|  |  |_/    //
//                                                   //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract mom is ERC721Creator {
    constructor() ERC721Creator("Momo Art", "mom") {}
}