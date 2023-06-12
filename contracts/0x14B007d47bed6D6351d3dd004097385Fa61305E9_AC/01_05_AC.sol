// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ancient Crows
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//                                                                       //
//      ^    ^    ^    ^    ^    ^    ^       ^    ^    ^    ^    ^      //
//     /A\  /n\  /c\  /i\  /e\  /n\  /t\     /C\  /r\  /o\  /w\  /s\     //
//    <___><___><___><___><___><___><___>   <___><___><___><___><___>    //
//                                                                       //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract AC is ERC1155Creator {
    constructor() ERC1155Creator("Ancient Crows", "AC") {}
}