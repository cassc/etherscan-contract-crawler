// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Creator's collection by shintaro
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//     _______ _     _ _____ __   _ _______ _______  ______  _____     //
//     |______ |_____|   |   | \  |    |    |_____| |_____/ |     |    //
//     ______| |     | __|__ |  \_|    |    |     | |    \_ |_____|    //
//                                                                     //
//                                                                     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract ccbs is ERC1155Creator {
    constructor() ERC1155Creator("Creator's collection by shintaro", "ccbs") {}
}