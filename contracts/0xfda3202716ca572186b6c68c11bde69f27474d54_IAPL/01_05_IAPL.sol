// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: i apologize.
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//    Let this apology forever be printed on this piece of art.    //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract IAPL is ERC721Creator {
    constructor() ERC721Creator("i apologize.", "IAPL") {}
}