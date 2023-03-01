// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions by Darklunni
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                                                          //
//      _                           _                       //
//     /_` _/._/_._  _   _  /_     / | _  _/_/   _  _  .    //
//    /_,/_// / //_// /_\  /_//_/ /_.'/_|//\//_// // //     //
//                            _/                            //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract ED is ERC1155Creator {
    constructor() ERC1155Creator("Editions by Darklunni", "ED") {}
}