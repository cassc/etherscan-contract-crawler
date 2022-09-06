// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aoladestiny
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//    Aola destiny is a collection of 100 pieces that brings ART to life. Aola Destiny mixes art with customs, statutes, clothes, architectural design, social standards, and traditions to depict all facets of human society.    //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Aoladestiny is ERC721Creator {
    constructor() ERC721Creator("Aoladestiny", "Aoladestiny") {}
}