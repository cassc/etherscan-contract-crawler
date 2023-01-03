// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Free as a Bird (Edition)
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                         //
//                                                                                                                                                                         //
//    Our name is "Conte art" we are going to make you feel best with our magic pen.                                                                                       //
//    Conte has members currently on their team:                                                                                                                           //
//    Mr. Mh. Enteshari and Ms. Akram Kholghi                                                                                                                              //
//    We work together on Art works for NFT.                                                                                                                               //
//    "Free as a bird"is the name of my personal children's book, it has 40 illustrations frame, I'm working on since 2019 and I will finish the book till spring 2023.    //
//    The artist of "Free as a Bird" collection is Ms. Akram Kholghi                                                                                                       //
//                                                                                                                                                                         //
//                                                                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PERSIAN is ERC721Creator {
    constructor() ERC721Creator("Free as a Bird (Edition)", "PERSIAN") {}
}