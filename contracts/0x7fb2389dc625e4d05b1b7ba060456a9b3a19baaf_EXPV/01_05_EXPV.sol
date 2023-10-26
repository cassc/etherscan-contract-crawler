// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Expansion Voucher
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    Evolve your art, choose wisely...    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract EXPV is ERC721Creator {
    constructor() ERC721Creator("Expansion Voucher", "EXPV") {}
}