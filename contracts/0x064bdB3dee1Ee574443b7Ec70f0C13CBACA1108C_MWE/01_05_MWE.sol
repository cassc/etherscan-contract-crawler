// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Marvelous Worlds of Elena
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//    There are my digital worlds. Each of them are detailed and has own story.    //
//                                                                                 //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////


contract MWE is ERC721Creator {
    constructor() ERC721Creator("Marvelous Worlds of Elena", "MWE") {}
}