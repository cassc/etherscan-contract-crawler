// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Evil Eye / Nazar
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    A collection of various Turkish Evil Eyes    //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract EEN is ERC721Creator {
    constructor() ERC721Creator("Evil Eye / Nazar", "EEN") {}
}