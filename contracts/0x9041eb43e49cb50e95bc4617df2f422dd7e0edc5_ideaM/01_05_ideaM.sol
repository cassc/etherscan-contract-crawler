// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Manifold x ideartist
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//    hi hello if you somehow see this, come and say hi on my Twitter account!     //
//                                                                                 //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////


contract ideaM is ERC721Creator {
    constructor() ERC721Creator("Manifold x ideartist", "ideaM") {}
}