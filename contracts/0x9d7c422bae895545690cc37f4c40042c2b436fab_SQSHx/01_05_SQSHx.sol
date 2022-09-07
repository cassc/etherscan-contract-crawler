// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Squish Private Reserve
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                               //
//                                                                                                                               //
//    SQUISH PRIVATE RESERVE                                                                                                     //
//                                                                                                                               //
//                                                                                                                               //
//                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SQSHx is ERC721Creator {
    constructor() ERC721Creator("Squish Private Reserve", "SQSHx") {}
}