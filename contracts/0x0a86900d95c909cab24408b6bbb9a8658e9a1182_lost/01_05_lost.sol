// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE ANGRY MAN
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    ANGER.    //
//              //
//              //
//////////////////


contract lost is ERC721Creator {
    constructor() ERC721Creator("THE ANGRY MAN", "lost") {}
}