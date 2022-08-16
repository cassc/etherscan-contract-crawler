// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sousourada
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    Photography Sousourada    //
//                              //
//                              //
//////////////////////////////////


contract Sous is ERC721Creator {
    constructor() ERC721Creator("Sousourada", "Sous") {}
}