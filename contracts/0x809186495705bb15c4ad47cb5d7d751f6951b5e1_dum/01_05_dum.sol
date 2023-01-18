// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: dum jpeg
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    no    //
//          //
//          //
//////////////


contract dum is ERC721Creator {
    constructor() ERC721Creator("dum jpeg", "dum") {}
}