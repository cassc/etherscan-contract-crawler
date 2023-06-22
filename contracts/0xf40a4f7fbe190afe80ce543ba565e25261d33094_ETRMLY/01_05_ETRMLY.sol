// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ETHER x MILADY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    ETHER x MILADY    //
//                      //
//                      //
//////////////////////////


contract ETRMLY is ERC721Creator {
    constructor() ERC721Creator("ETHER x MILADY", "ETRMLY") {}
}