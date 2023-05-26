// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nick Davis Legacy Collection
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    Nick Davies Legacy Collection    //
//                                     //
//                                     //
/////////////////////////////////////////


contract NDLC is ERC1155Creator {
    constructor() ERC1155Creator("Nick Davis Legacy Collection", "NDLC") {}
}