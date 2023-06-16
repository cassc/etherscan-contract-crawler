// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PixelVerse
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////
//         //
//         //
//    ❎    //
//         //
//         //
/////////////


contract PXL is ERC1155Creator {
    constructor() ERC1155Creator("PixelVerse", "PXL") {}
}