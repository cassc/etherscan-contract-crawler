// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EsoTeros Burn Redeem
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    Esoteros Burn Events     //
//                             //
//                             //
/////////////////////////////////


contract EBR is ERC1155Creator {
    constructor() ERC1155Creator("EsoTeros Burn Redeem", "EBR") {}
}