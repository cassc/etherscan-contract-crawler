// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ghost Train Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//         ooOOOO                   //
//        oo      _____             //
//       _I__n_n__||_|| ________    //
//     >(_________|_7_|-|______|    //
//      /o ()() ()() o   oo  oo     //
//                                  //
//                                  //
//////////////////////////////////////


contract GhostTrainE is ERC721Creator {
    constructor() ERC721Creator("Ghost Train Editions", "GhostTrainE") {}
}