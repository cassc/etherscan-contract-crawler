// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0xBartender's Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//      _    _                         //
//     / /  /_)_  __/__  _   _/_  _    //
//    /_/></_)/_|/ / /_'/ //_//_'/     //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract OxBe is ERC1155Creator {
    constructor() ERC1155Creator("0xBartender's Editions", "OxBe") {}
}