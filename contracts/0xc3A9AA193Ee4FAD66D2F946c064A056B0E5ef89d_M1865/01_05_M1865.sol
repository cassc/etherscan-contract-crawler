// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MUSK: 1865
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    MUSK: 1865    //
//                  //
//                  //
//////////////////////


contract M1865 is ERC721Creator {
    constructor() ERC721Creator("MUSK: 1865", "M1865") {}
}