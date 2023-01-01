// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JimmyCrypto888
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//    JimmyCrypto888     //
//                       //
//                       //
//                       //
///////////////////////////


contract JimmyCrypto888 is ERC1155Creator {
    constructor() ERC1155Creator("JimmyCrypto888", "JimmyCrypto888") {}
}