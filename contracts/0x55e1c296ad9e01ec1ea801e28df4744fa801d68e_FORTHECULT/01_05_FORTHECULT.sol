// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: For the Cult
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                                                                                              //
//    Doing it for the                                                                          //
//                                                                                              //
//      ^    ^    ^    ^                                                                        //
//     /C\  /U\  /L\  /T\                                                                       //
//    <___><___><___><___>ure                                                                   //
//                                                                                              //
//    A contract for the minting and dissemination of Cult Crypto Art propaganda and merch.     //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////


contract FORTHECULT is ERC1155Creator {
    constructor() ERC1155Creator("For the Cult", "FORTHECULT") {}
}