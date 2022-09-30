// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Gnothole
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    <:-)    //
//            //
//            //
////////////////


contract GNOT is ERC721Creator {
    constructor() ERC721Creator("The Gnothole", "GNOT") {}
}