// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: nudetripnft
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    Editions x Marat Safin    //
//                              //
//                              //
//////////////////////////////////


contract mss is ERC721Creator {
    constructor() ERC721Creator("nudetripnft", "mss") {}
}