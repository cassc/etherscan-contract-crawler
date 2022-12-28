// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: pjway1 Ξ Ape
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    pjway1 Ξ Ape    //
//                    //
//                    //
////////////////////////


contract PJAPE is ERC721Creator {
    constructor() ERC721Creator(unicode"pjway1 Ξ Ape", "PJAPE") {}
}