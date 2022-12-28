// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bankless
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    Bankless    //
//                //
//                //
////////////////////


contract Bankless is ERC721Creator {
    constructor() ERC721Creator("Bankless", "Bankless") {}
}