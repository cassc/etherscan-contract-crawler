// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Trizton 1/1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                               //
//                                                                                               //
//    Finally, a contract to my own name. I have spent the majority of my creative endeavors     //
//    under a pseudonym. I have been known by many names over the years.                         //
//    As I grow into my potential, and as I further learn about myself, the need to              //
//    carry on under a false name dwindles. My name is Trizton. My art is my spirit.             //
//    From now on, I will introduce myself as me, not a character.                               //
//                                                                                               //
//                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////


contract TRIZ is ERC721Creator {
    constructor() ERC721Creator("Trizton 1/1", "TRIZ") {}
}