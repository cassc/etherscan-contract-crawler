// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moises Art Gallery
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                          //
//                                                                                                                          //
//    My art is reflection. Looking through the eyes of those who do not ignore. What is hidden in the simple. Just see!    //
//                                                                                                                          //
//                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MAGallery is ERC721Creator {
    constructor() ERC721Creator("Moises Art Gallery", "MAGallery") {}
}