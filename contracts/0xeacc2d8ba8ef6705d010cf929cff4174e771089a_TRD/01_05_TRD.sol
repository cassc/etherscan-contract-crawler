// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Triad
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    _____________________ ________        //
//    \__    ___/\______   \\______ \       //
//      |    |    |       _/ |    |  \      //
//      |    |    |    |   \ |    `   \     //
//      |____|    |____|_  //_______  /     //
//                       \/         \/      //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract TRD is ERC1155Creator {
    constructor() ERC1155Creator("The Triad", "TRD") {}
}