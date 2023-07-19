// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: icon
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    🔳    //
//          //
//          //
//////////////


contract ICN is ERC721Creator {
    constructor() ERC721Creator("icon", "ICN") {}
}