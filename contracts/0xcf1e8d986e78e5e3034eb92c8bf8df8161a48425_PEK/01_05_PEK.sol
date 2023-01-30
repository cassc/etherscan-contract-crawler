// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PEK
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//    _________________________  __.    //
//    \______   \_   _____/    |/ _|    //
//     |     ___/|    __)_|      <      //
//     |    |    |        \    |  \     //
//     |____|   /_______  /____|__ \    //
//                      \/        \/    //
//                                      //
//                                      //
//////////////////////////////////////////


contract PEK is ERC1155Creator {
    constructor() ERC1155Creator("PEK", "PEK") {}
}