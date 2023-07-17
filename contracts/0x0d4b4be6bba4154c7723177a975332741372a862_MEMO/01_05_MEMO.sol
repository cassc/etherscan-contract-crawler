// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Memification of Being
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    🙈    //
//          //
//          //
//////////////


contract MEMO is ERC1155Creator {
    constructor() ERC1155Creator("Memification of Being", "MEMO") {}
}