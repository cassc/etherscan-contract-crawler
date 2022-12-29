// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Right Click Save The Planet
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    Right Click Save The Planet    //
//                                   //
//                                   //
///////////////////////////////////////


contract RCSTP is ERC1155Creator {
    constructor() ERC1155Creator("Right Click Save The Planet", "RCSTP") {}
}