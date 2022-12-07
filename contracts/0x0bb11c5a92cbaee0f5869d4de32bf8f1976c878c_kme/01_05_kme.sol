// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: k$ editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    k$ edish    //
//                //
//                //
////////////////////


contract kme is ERC1155Creator {
    constructor() ERC1155Creator("k$ editions", "kme") {}
}