// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Desolation of Pepe
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    pep911    //
//              //
//              //
//////////////////


contract DPEP is ERC721Creator {
    constructor() ERC721Creator("The Desolation of Pepe", "DPEP") {}
}