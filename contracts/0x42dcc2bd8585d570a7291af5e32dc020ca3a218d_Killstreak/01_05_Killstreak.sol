// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Killstreak
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    Killstreak    //
//                  //
//                  //
//////////////////////


contract Killstreak is ERC721Creator {
    constructor() ERC721Creator("Killstreak", "Killstreak") {}
}