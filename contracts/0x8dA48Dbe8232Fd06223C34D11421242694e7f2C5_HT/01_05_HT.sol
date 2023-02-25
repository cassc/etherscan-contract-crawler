// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HexyTexy
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    HexyTexy    //
//                //
//                //
////////////////////


contract HT is ERC1155Creator {
    constructor() ERC1155Creator("HexyTexy", "HT") {}
}