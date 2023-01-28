// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NRL Open Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//      o          o    o__ __o         o              //
//     <|\        <|>  <|     v\       <|>             //
//     / \\o      / \  / \     <\      / \             //
//     \o/ v\     \o/  \o/     o/      \o/             //
//      |   <\     |    |__  _<|        |              //
//     / \    \o  / \   |       \      / \             //
//     \o/     v\ \o/  <o>       \o    \o/             //
//      |       <\ |    |         v\    |              //
//     / \        < \  / \         <\  / \ _\o__/_     //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract NRL is ERC1155Creator {
    constructor() ERC1155Creator("NRL Open Edition", "NRL") {}
}