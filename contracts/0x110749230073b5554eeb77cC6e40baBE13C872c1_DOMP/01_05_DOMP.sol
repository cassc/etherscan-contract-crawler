// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Melting Pot
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//                                                                //
//    ___                                          __             //
//     ) ( _   _     )\/)  _   ) _)_ o  _   _      )_) _  _)_     //
//    (   ) ) )_)   (  (  )_) (  (_  ( ) ) (_(    /   (_) (_      //
//           (_          (_                  _)                   //
//                                                                //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract DOMP is ERC1155Creator {
    constructor() ERC1155Creator("The Melting Pot", "DOMP") {}
}