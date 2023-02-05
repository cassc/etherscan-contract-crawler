// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RisshunDaikichi
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                                                                      //
//      ^    ^    ^    ^    ^    ^    ^       ^    ^    ^    ^    ^    ^    ^    ^      //
//     /R\  /i\  /s\  /s\  /h\  /u\  /n\     /D\  /a\  /i\  /k\  /i\  /c\  /h\  /i\     //
//    <___><___><___><___><___><___><___>   <___><___><___><___><___><___><___><___>    //
//                                                                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////


contract RisshunDaikichi is ERC1155Creator {
    constructor() ERC1155Creator("RisshunDaikichi", "RisshunDaikichi") {}
}