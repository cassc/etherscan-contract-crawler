// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MinaHloy
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                                         //
//     )\/) o  _   _  ( _   )  _           //
//    (  (  ( ) ) (_(  ) ) (  (_) (_(      //
//                                  _)     //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract Mhloy is ERC1155Creator {
    constructor() ERC1155Creator("MinaHloy", "Mhloy") {}
}