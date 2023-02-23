// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Roze
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//    From the ashes of the Roze, it can become something new.     //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract RSZ is ERC721Creator {
    constructor() ERC721Creator("Roze", "RSZ") {}
}