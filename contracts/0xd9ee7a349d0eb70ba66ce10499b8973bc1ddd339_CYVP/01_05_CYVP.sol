// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Crypto Yum VIP PASS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    Yusuke Toda    //
//                   //
//                   //
///////////////////////


contract CYVP is ERC1155Creator {
    constructor() ERC1155Creator("Crypto Yum VIP PASS", "CYVP") {}
}