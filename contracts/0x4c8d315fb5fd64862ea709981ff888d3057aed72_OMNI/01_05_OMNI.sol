// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Omnipresent
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    Clearing__Contract    //
//                          //
//                          //
//////////////////////////////


contract OMNI is ERC721Creator {
    constructor() ERC721Creator("Omnipresent", "OMNI") {}
}