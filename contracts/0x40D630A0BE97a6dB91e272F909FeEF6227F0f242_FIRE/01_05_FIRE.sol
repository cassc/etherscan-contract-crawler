// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FIRE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    My ascii mark is actualy only this.    //
//                                           //
//                                           //
///////////////////////////////////////////////


contract FIRE is ERC721Creator {
    constructor() ERC721Creator("FIRE", "FIRE") {}
}