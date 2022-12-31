// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: euphoria
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    euphoria by alister mori     //
//                                 //
//                                 //
/////////////////////////////////////


contract euphoria is ERC721Creator {
    constructor() ERC721Creator("euphoria", "euphoria") {}
}