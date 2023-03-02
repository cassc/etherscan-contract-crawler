// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BlablaTez Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    Reflecting on the passage of Time.     //
//                                           //
//                                           //
///////////////////////////////////////////////


contract BLA is ERC721Creator {
    constructor() ERC721Creator("BlablaTez Editions", "BLA") {}
}