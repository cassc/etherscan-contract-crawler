// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Great Adventure
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    (\                            //
//    \'\                           //
//     \'\     __________           //
//     / '|   ()_________)          //
//     \ '/    \ ~~~~~~~~ \         //
//       \       \ ~~~~~~   \       //
//       ==).      \__________\     //
//      (__)       ()__________)    //
//                                  //
//                                  //
//////////////////////////////////////


contract ADVNTR is ERC721Creator {
    constructor() ERC721Creator("The Great Adventure", "ADVNTR") {}
}