// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Link Up*
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//     ________                     //
//     /_  __/ /_  ___              //
//      / / / __ \/ _ \             //
//     / / / / / /  __/             //
//    /_/ /_/ /_/\___/  __          //
//       / /   (_)___  / /__        //
//      / /   / / __ \/ //_/        //
//     / /___/ / / / / ,<           //
//    /_____/_/_/ /_/_/|_|          //
//      / / / /___                  //
//     / / / / __ \                 //
//    / /_/ / /_/ /                 //
//    \____/ .___/                  //
//        /_/                       //
//                                  //
//                                  //
//////////////////////////////////////


contract TLU is ERC1155Creator {
    constructor() ERC1155Creator("The Link Up*", "TLU") {}
}