// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Grails II MintPass
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    Grails II MintPass    //
//                          //
//                          //
//////////////////////////////


contract GllMP is ERC721Creator {
    constructor() ERC721Creator("Grails II MintPass", "GllMP") {}
}