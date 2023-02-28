// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Corralled
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    _                                 //
//    /   _  ._  _. |  _      ._ _      //
//    \_ (_) |  (_| | (/_ |_| | | |     //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract Coral is ERC721Creator {
    constructor() ERC721Creator("Corralled", "Coral") {}
}