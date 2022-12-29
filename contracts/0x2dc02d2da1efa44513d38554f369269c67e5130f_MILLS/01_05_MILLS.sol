// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mills
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
//                                               MILLS                                               //
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////


contract MILLS is ERC721Creator {
    constructor() ERC721Creator("Mills", "MILLS") {}
}