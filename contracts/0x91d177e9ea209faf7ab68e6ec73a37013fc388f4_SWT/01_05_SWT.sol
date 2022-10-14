// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Small World
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    Small World, an experiment by Trizton.     //
//                                               //
//                                               //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract SWT is ERC721Creator {
    constructor() ERC721Creator("Small World", "SWT") {}
}