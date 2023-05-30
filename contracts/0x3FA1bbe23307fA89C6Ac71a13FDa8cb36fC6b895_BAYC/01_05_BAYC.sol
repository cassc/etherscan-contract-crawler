// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bored Ape Yacht Club x Ethereum
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    Bored Ape Yacht Club x Ethereum    //
//                                       //
//                                       //
///////////////////////////////////////////


contract BAYC is ERC1155Creator {
    constructor() ERC1155Creator() {}
}