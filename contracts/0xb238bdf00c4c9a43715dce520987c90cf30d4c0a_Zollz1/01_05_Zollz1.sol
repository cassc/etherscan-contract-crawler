// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFTversary 1
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    Zollz1    //
//              //
//              //
//////////////////


contract Zollz1 is ERC1155Creator {
    constructor() ERC1155Creator("NFTversary 1", "Zollz1") {}
}