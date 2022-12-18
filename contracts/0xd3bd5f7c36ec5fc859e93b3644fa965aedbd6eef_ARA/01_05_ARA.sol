// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Argentinean Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    ARA%    //
//            //
//            //
////////////////


contract ARA is ERC721Creator {
    constructor() ERC721Creator("Argentinean Art", "ARA") {}
}