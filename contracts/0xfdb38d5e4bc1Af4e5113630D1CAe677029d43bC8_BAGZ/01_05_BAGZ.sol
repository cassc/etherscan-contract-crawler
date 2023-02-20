// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shopping Bagz
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////
//         //
//         //
//    $    //
//         //
//         //
/////////////


contract BAGZ is ERC1155Creator {
    constructor() ERC1155Creator("Shopping Bagz", "BAGZ") {}
}