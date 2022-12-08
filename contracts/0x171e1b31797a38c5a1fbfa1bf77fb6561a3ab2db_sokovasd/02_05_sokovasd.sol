// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sp.Dr.By Sokova
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                              //
//                             __               //
//    |<<  >>  |  /  >>  |  | |  | |<<  __|     //
//    --  |  | |<<  |  | |  | |><| --  |<<|     //
//    >>|  <<  |  \  <<   \/  |  | >>| |__|     //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract sokovasd is ERC721Creator {
    constructor() ERC721Creator("Sp.Dr.By Sokova", "sokovasd") {}
}