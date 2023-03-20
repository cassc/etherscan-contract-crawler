// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Inkscapes: Algorithmic Dreams
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//                                                                                    //
//    Inkscapes: Algorithmic Dreams                                                   //
//                                                                                    //
//    A collaboration between Swickie x Kenny Vaden combining code & analog media.    //
//                                                                                    //
//    Debuted at OtherBlock: SuperCharged LA, March 18, 2023.                         //
//                                                                                    //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////


contract InkDreams is ERC721Creator {
    constructor() ERC721Creator("Inkscapes: Algorithmic Dreams", "InkDreams") {}
}