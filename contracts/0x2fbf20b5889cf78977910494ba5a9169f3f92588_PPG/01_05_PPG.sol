// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PAJI PASS GENESIS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    paji.eth    //
//                //
//                //
////////////////////


contract PPG is ERC1155Creator {
    constructor() ERC1155Creator("PAJI PASS GENESIS", "PPG") {}
}