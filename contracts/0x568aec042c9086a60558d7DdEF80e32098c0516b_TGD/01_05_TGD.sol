// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Trap 2023 Drops
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    trappppp    //
//                //
//                //
////////////////////


contract TGD is ERC1155Creator {
    constructor() ERC1155Creator("Trap 2023 Drops", "TGD") {}
}