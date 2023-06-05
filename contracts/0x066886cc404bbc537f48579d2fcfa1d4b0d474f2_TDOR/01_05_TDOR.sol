// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Death of Real
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//     +-++-++-+ +-++-++-++-++-+ +-++-+ +-++-++-++-+    //
//     |T||h||e| |D||e||a||t||h| |o||f| |R||e||a||l|    //
//     +-++-++-+ +-++-++-++-++-+ +-++-+ +-++-++-++-+    //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract TDOR is ERC721Creator {
    constructor() ERC721Creator("The Death of Real", "TDOR") {}
}