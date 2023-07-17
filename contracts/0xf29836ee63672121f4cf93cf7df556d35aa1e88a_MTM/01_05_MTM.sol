// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Muster The Monsters
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                       o                          //
//                      <|>                         //
//                      < >                         //
//     \o__ __o__ __o    |      \o__ __o__ __o      //
//      |     |     |>   o__/_   |     |     |>     //
//     / \   / \   / \   |      / \   / \   / \     //
//     \o/   \o/   \o/   |      \o/   \o/   \o/     //
//      |     |     |    o       |     |     |      //
//     / \   / \   / \   <\__   / \   / \   / \     //
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract MTM is ERC1155Creator {
    constructor() ERC1155Creator("Muster The Monsters", "MTM") {}
}