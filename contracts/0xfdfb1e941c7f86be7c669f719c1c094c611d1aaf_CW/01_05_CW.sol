// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Crypt0Warr10r
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Crypt0Warr10r    //
//                     //
//                     //
/////////////////////////


contract CW is ERC721Creator {
    constructor() ERC721Creator("Crypt0Warr10r", "CW") {}
}