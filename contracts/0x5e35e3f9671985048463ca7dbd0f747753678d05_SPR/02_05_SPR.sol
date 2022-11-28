// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Serpent Pimp Remix
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    <S><P><R>    //
//                 //
//                 //
/////////////////////


contract SPR is ERC721Creator {
    constructor() ERC721Creator("Serpent Pimp Remix", "SPR") {}
}