// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PEPES
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    Airdrops    //
//                //
//                //
////////////////////


contract PEPES is ERC1155Creator {
    constructor() ERC1155Creator("PEPES", "PEPES") {}
}