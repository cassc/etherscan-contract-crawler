// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fish & Friends Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Fish & Friends.    //
//                       //
//                       //
///////////////////////////


contract FISH is ERC721Creator {
    constructor() ERC721Creator("Fish & Friends Collection", "FISH") {}
}