// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tucker
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    Tucker    //
//              //
//              //
//////////////////


contract TUCK is ERC721Creator {
    constructor() ERC721Creator("Tucker", "TUCK") {}
}