// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JustArtOut PopFusion
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    PopArt/Cubism Artwork by Akashi30.           //
//    All unauthorised use of Art is prohibited    //
//    and will be Prosecuted.                      //
//                                                 //
//    Available on Twitter “Akashi30eth”           //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract JAOPF is ERC1155Creator {
    constructor() ERC1155Creator("JustArtOut PopFusion", "JAOPF") {}
}