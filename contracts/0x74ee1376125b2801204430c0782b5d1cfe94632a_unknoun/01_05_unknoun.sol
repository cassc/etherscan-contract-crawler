// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Unknouns
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//    We thrive in the shadows, hidden away underneath your bed, in your closet     //
//    and in your head, our identities a mystery, we are Unknouns!                  //
//                                                                                  //
//                                                                                  //
//    T H E   U N K N O U N S                                                       //
//                                                                                  //
//    ⌐◪-◪   ⌐◒-◒                                                                   //
//                                                                                  //
//    ⌐💀-💀  ⌐♥-♥                                                                  //
//                                                                                  //
//    ⌐♥-♥   ⌐♥-♥                                                                   //
//                                                                                  //
//    ⌐◪-◪   ⌐▨-▨                                                                   //
//                                                                                  //
//    ⌐@[email protected]                                                                          //
//                                                                                  //
//                                                                                  //
//    We are nouns. We are CC0.                                                     //
//                                                                                  //
//    Unknouns come from the mind of tortita and the pencil of Greta Gremplin,      //
//    together they’ve created a collection of misfits, mysterious figures          //
//    that are rarely seen in the world of nouns.                                   //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


contract unknoun is ERC721Creator {
    constructor() ERC721Creator("The Unknouns", "unknoun") {}
}