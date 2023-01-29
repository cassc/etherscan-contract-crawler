// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Collabs & Commissions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    Collabs & Commissions    //
//                             //
//                             //
/////////////////////////////////


contract CnC is ERC721Creator {
    constructor() ERC721Creator("Collabs & Commissions", "CnC") {}
}