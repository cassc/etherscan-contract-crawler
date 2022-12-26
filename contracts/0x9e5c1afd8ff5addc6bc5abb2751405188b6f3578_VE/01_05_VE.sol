// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    VE    //
//          //
//          //
//////////////


contract VE is ERC721Creator {
    constructor() ERC721Creator("VE", "VE") {}
}