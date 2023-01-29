// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SA PASS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//    SQUADALPHA PASS    //
//                       //
//                       //
///////////////////////////


contract SAPASS is ERC1155Creator {
    constructor() ERC1155Creator("SA PASS", "SAPASS") {}
}