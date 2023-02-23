// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CryptoWagakki Collaborative
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    cw-collab    //
//                 //
//                 //
/////////////////////


contract cwcollab is ERC1155Creator {
    constructor() ERC1155Creator("CryptoWagakki Collaborative", "cwcollab") {}
}