// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rekts - RG Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    rekts by pepegm, inspired by checks by jackbutcher    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract RKTS is ERC721Creator {
    constructor() ERC721Creator("Rekts - RG Edition", "RKTS") {}
}