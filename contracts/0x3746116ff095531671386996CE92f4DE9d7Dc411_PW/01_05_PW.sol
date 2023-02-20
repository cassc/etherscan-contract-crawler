// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PixelWest
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    Pixel West World    //
//                        //
//                        //
////////////////////////////


contract PW is ERC1155Creator {
    constructor() ERC1155Creator("PixelWest", "PW") {}
}