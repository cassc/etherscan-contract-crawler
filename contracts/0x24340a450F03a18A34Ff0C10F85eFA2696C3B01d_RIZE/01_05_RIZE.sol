// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RISE CHAN'S EXPLORATION
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//      o         o        o__ __o        o__ __o         o          o   \o       o/     //
//     <|>       <|>      /v     v\      <|     v\       <|\        <|>   v\     /v      //
//     < >       < >     />       <\     / \     <\      / \\o      / \    <\   />       //
//      |         |    o/           \o   \o/     o/      \o/ v\     \o/      \o/         //
//      o__/_ _\__o   <|             |>   |__  _<|        |   <\     |        |          //
//      |         |    \\           //    |       \      / \    \o  / \      / \         //
//     <o>       <o>     \         /     <o>       \o    \o/     v\ \o/      \o/         //
//      |         |       o       o       |         v\    |       <\ |        |          //
//     / \       / \      <\__ __/>      / \         <\  / \        < \      / \         //
//                                                                                       //
//                                                                                       //
//                                                                                       //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract RIZE is ERC1155Creator {
    constructor() ERC1155Creator("RISE CHAN'S EXPLORATION", "RIZE") {}
}