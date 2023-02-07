// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MinCash Photography
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    MinCash’s Photography Collection.    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract MCASH is ERC721Creator {
    constructor() ERC721Creator("MinCash Photography", "MCASH") {}
}