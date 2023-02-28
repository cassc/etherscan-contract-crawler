// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CH DAO PASS #2
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    CH DAO    //
//              //
//              //
//////////////////


contract CHDAO is ERC1155Creator {
    constructor() ERC1155Creator("CH DAO PASS #2", "CHDAO") {}
}