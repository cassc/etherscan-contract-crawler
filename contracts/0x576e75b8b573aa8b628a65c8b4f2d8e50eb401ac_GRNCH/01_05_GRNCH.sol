// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GrinchMas
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    Have a jolly christmas    //
//                              //
//                              //
//////////////////////////////////


contract GRNCH is ERC721Creator {
    constructor() ERC721Creator("GrinchMas", "GRNCH") {}
}