// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: fock it
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    yo    //
//          //
//          //
//////////////


contract fock is ERC721Creator {
    constructor() ERC721Creator("fock it", "fock") {}
}