// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: azure
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//    .- -.-. ..- .-     //
//                       //
//                       //
///////////////////////////


contract AZR is ERC1155Creator {
    constructor() ERC1155Creator("azure", "AZR") {}
}