// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Meaning Within The Universes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//      o          o    o              o   ____o__ __o____   o         o      //
//     <|\        /|>  <|>            <|>   /   \   /   \   <|>       <|>     //
//     / \\o    o// \  / \            / \        \o/        / \       / \     //
//     \o/ v\  /v \o/  \o/            \o/         |         \o/       \o/     //
//      |   <\/>   |    |              |         < >         |         |      //
//     / \        / \  < >            < >         |         < >       < >     //
//     \o/        \o/   \o    o/\o    o/          o          \         /      //
//      |          |     v\  /v  v\  /v          <|           o       o       //
//     / \        / \     <\/>    <\/>           / \          <\__ __/>       //
//                                                                            //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract MWTU is ERC1155Creator {
    constructor() ERC1155Creator("Meaning Within The Universes", "MWTU") {}
}