// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CryptoWagakki Gift for Mint 1155
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    cwg1155    //
//               //
//               //
///////////////////


contract cwg1155 is ERC1155Creator {
    constructor() ERC1155Creator("CryptoWagakki Gift for Mint 1155", "cwg1155") {}
}