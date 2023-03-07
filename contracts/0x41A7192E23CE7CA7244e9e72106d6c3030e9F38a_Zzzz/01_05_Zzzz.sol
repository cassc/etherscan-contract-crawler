// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: (but on-chain)
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    at least this will be on chain.    //
//                                       //
//                                       //
///////////////////////////////////////////


contract Zzzz is ERC1155Creator {
    constructor() ERC1155Creator("(but on-chain)", "Zzzz") {}
}