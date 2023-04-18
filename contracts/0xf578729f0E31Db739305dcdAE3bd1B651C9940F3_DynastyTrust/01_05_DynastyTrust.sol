// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dynasty Trust
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    皇朝信託 Dynasty Trust    //
//                          //
//                          //
//////////////////////////////


contract DynastyTrust is ERC721Creator {
    constructor() ERC721Creator("Dynasty Trust", "DynastyTrust") {}
}