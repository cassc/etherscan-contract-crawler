// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Cluster
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    The Cluster    //
//                   //
//                   //
///////////////////////


contract Cluster is ERC721Creator {
    constructor() ERC721Creator("The Cluster", "Cluster") {}
}