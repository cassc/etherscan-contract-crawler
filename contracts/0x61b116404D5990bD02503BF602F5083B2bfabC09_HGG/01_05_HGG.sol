// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hayabusa Girls Girichoco
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////
//         //
//         //
//    ♡    //
//         //
//         //
/////////////


contract HGG is ERC1155Creator {
    constructor() ERC1155Creator("Hayabusa Girls Girichoco", "HGG") {}
}