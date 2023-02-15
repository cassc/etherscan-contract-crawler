// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: kvd_works
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//                                   //
//     |     _|       _  __ |  _     //
//     |<\_/(_|___\^/(_) |  |<_>     //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract KVD is ERC1155Creator {
    constructor() ERC1155Creator("kvd_works", "KVD") {}
}