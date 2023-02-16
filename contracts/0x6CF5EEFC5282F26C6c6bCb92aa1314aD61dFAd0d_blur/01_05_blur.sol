// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BanksyBlends
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    Banksy    //
//              //
//              //
//////////////////


contract blur is ERC1155Creator {
    constructor() ERC1155Creator("BanksyBlends", "blur") {}
}