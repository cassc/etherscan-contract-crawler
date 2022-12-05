// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lee Pengelly Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//                                                                                   //
//                   __                               ___                            //
//     )   _   _     )_) _   _   _     _   ) )        )_  _ ) o _)_ o  _   _   _     //
//    (__ )_) )_)   /   )_) ) ) (_(   )_) ( ( (_(    (__ (_(  ( (_  ( (_) ) ) (      //
//       (_  (_        (_         _) (_         _)                            _)     //
//                                                                                   //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract LPEDS is ERC1155Creator {
    constructor() ERC1155Creator("Lee Pengelly Editions", "LPEDS") {}
}