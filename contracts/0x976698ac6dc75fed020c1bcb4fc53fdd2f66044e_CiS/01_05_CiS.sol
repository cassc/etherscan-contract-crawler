// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cute is scary.
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    Cute is scary.    //
//                      //
//                      //
//////////////////////////


contract CiS is ERC721Creator {
    constructor() ERC721Creator("Cute is scary.", "CiS") {}
}