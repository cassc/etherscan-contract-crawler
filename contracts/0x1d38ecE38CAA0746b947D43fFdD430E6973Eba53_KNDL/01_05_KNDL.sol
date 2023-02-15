// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KNDL by KEVIN ABOSCH
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    //KNDL by KEVIN ABOSCH    //
//                              //
//                              //
//////////////////////////////////


contract KNDL is ERC721Creator {
    constructor() ERC721Creator("KNDL by KEVIN ABOSCH", "KNDL") {}
}