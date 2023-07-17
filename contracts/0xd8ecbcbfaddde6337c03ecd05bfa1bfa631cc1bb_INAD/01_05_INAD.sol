// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: INAD
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Stand with Crypto    //
//                         //
//                         //
/////////////////////////////


contract INAD is ERC721Creator {
    constructor() ERC721Creator("INAD", "INAD") {}
}