// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 8bit Physical Abstract Works
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    8bit Physical abstract works    //
//                                    //
//                                    //
////////////////////////////////////////


contract BIT is ERC721Creator {
    constructor() ERC721Creator("8bit Physical Abstract Works", "BIT") {}
}