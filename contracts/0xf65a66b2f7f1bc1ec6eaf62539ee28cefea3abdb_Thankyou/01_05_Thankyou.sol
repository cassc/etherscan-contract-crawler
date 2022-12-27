// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SPECIAL EDITION: Meowy Xmas Tree
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//    Special thanks to my Meowyxmas Collectors!     //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract Thankyou is ERC721Creator {
    constructor() ERC721Creator("SPECIAL EDITION: Meowy Xmas Tree", "Thankyou") {}
}