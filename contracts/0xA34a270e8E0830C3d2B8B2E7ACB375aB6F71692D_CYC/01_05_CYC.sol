// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Crypto Yum Collection
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    Yusuke Toda    //
//                   //
//                   //
///////////////////////


contract CYC is ERC1155Creator {
    constructor() ERC1155Creator("Crypto Yum Collection", "CYC") {}
}