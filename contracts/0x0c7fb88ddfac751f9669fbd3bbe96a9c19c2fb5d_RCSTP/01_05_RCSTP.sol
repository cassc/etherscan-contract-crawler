// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Right Click Save The Planet
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    Right Click Save The Planet    //
//                                   //
//                                   //
///////////////////////////////////////


contract RCSTP is ERC721Creator {
    constructor() ERC721Creator("Right Click Save The Planet", "RCSTP") {}
}