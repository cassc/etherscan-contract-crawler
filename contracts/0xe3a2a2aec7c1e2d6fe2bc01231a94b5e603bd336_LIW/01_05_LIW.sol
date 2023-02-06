// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Life Is War
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Life is War    //
//                   //
//                   //
///////////////////////


contract LIW is ERC721Creator {
    constructor() ERC721Creator("Life Is War", "LIW") {}
}