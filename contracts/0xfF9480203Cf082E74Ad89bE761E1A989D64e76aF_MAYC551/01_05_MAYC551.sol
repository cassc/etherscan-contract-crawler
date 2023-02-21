// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MAYC551
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    Goldberg    //
//                //
//                //
////////////////////


contract MAYC551 is ERC1155Creator {
    constructor() ERC1155Creator("MAYC551", "MAYC551") {}
}