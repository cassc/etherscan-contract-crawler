// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    ________   ___________    //
//    \_____  \  \_   _____/    //
//     /   |   \  |    __)_     //
//    /    |    \ |        \    //
//    \_______  //_______  /    //
//            \/         \/     //
//                              //
//                              //
//////////////////////////////////


contract OE is ERC1155Creator {
    constructor() ERC1155Creator("OE", "OE") {}
}