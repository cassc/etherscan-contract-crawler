// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PoW-improved masterpieces
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//                                                                               //
//    50 6F 57  69 6D 70 72 6F 76 65 64  6D 61 73 74 65 72 70 69 65 63 65 73     //
//                                                                               //
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////


contract PoWIM is ERC721Creator {
    constructor() ERC721Creator("PoW-improved masterpieces", "PoWIM") {}
}