// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: queue
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////
//             //
//             //
//    queue    //
//             //
//             //
/////////////////


contract queue is ERC1155Creator {
    constructor() ERC1155Creator("queue", "queue") {}
}