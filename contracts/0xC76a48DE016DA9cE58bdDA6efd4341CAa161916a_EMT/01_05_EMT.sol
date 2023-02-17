// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ethmoto
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    EMTOKB    //
//              //
//              //
//              //
//////////////////


contract EMT is ERC721Creator {
    constructor() ERC721Creator("ethmoto", "EMT") {}
}