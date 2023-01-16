// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Minimalism X
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    minimalismX3    //
//                    //
//                    //
////////////////////////


contract Mx3 is ERC721Creator {
    constructor() ERC721Creator("Minimalism X", "Mx3") {}
}