// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stillness
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//      __                                        //
//     (_ ` _)_ o  ) ) _   _   _  _               //
//    .__)  (_  ( ( ( ) ) )_) (  (                //
//                       (_   _) _)  by Fakeye    //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract STILL is ERC1155Creator {
    constructor() ERC1155Creator("Stillness", "STILL") {}
}