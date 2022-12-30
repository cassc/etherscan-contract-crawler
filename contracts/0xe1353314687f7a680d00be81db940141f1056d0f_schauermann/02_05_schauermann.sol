// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: schauermann
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    ☁️    //
//          //
//          //
//////////////


contract schauermann is ERC721Creator {
    constructor() ERC721Creator("schauermann", "schauermann") {}
}