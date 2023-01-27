// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GhostlyTripper
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//                                                                  //
//    Anonymous Ghost Lost In The Blockchain, 100x guaranteed 🚀    //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract Ghst is ERC721Creator {
    constructor() ERC721Creator("GhostlyTripper", "Ghst") {}
}