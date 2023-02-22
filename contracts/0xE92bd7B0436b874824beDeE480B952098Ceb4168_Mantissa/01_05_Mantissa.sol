// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mantissa
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Antwerp, Belgium.    //
//                         //
//                         //
/////////////////////////////


contract Mantissa is ERC1155Creator {
    constructor() ERC1155Creator("Mantissa", "Mantissa") {}
}