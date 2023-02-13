// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AI NYMPHIAD
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//                                                                       //
//                                                                       //
//     _     _       _     _     _     _     _     _     _     _         //
//      / \   / \     / \   / \   / \   / \   / \   / \   / \   / \      //
//     ( A ) ( I )   ( N ) ( Y ) ( M ) ( P ) ( H ) ( I ) ( A ) ( D )     //
//      \_/   \_/     \_/   \_/   \_/   \_/   \_/   \_/     \_/   \_/    //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract AIN is ERC721Creator {
    constructor() ERC721Creator("AI NYMPHIAD", "AIN") {}
}