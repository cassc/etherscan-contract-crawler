// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FANART
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    　〃∩ ∧＿∧       //
//    　⊂⌒(　･ω･)     //
//    　　＼_っ⌒/⌒c     //
//    　　　　⌒ ⌒       //
//                  //
//                  //
//////////////////////


contract FANART is ERC721Creator {
    constructor() ERC721Creator("FANART", "FANART") {}
}