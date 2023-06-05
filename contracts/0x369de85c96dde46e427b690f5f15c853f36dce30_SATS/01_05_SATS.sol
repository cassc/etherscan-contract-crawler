// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nakamoto
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                 //
//                                                                                                 //
//    If you don't believe me or don't get it, I don't have time to try to convince you, sorry.    //
//                                                                                                 //
//                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////


contract SATS is ERC1155Creator {
    constructor() ERC1155Creator("Nakamoto", "SATS") {}
}