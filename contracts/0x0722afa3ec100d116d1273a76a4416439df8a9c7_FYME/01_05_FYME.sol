// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fatality meme
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                              //
//                                                                                                                              //
//    vůbec tohle nechápu, ale mám rád ostravskou šunku a chci taky říct že pár lidi neví co je za den, ale mě je to uprdele    //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FYME is ERC721Creator {
    constructor() ERC721Creator("Fatality meme", "FYME") {}
}