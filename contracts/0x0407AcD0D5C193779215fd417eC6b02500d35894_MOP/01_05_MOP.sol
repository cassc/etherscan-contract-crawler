// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mountains of Pakistan
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    /^^       /^^    /^^^^     /^^^^^^^      //
//    /^ /^^   /^^^  /^^    /^^  /^^    /^^    //
//    /^^ /^^ / /^^/^^        /^^/^^    /^^    //
//    /^^  /^^  /^^/^^        /^^/^^^^^^^      //
//    /^^   /^  /^^/^^        /^^/^^           //
//    /^^       /^^  /^^     /^^ /^^           //
//    /^^       /^^    /^^^^     /^^           //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract MOP is ERC721Creator {
    constructor() ERC721Creator("Mountains of Pakistan", "MOP") {}
}