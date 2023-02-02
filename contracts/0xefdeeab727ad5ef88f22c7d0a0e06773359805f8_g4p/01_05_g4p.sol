// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: godatplay
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//                                                              d8,                    //
//                                                             `8P                     //
//                                                                                     //
//     d8888bd8888b  88bd8b,d88b?88,.d88b,d888b8b  .d888b.d888b,88bd8888b  88bd88b     //
//    d8P' `d8P' ?88 88P'`?8P'?8`?88'  ?8d8P' ?88  ?8b,  ?8b,   88d8P' ?88 88P' ?8b    //
//    88b   88b  d88d88  d88  88P 88b  d888b  ,88b   `?8b  `?8bd8888b  d88d88   88P    //
//    `?888P`?8888Pd88' d88'  88b 888888P`?88P'`88`?888P`?888Pd88'`?8888Pd88'   88b    //
//                                88P'                                                 //
//                               d88                                                   //
//                               ?8P                                                   //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract g4p is ERC721Creator {
    constructor() ERC721Creator("godatplay", "g4p") {}
}