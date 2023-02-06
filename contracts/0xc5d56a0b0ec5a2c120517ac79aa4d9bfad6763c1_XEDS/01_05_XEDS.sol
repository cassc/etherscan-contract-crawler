// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: XincEds
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//         |>     |>   |>     |>      //
//         __     _______     __      //
//        /  \   |       |   /  \     //
//        |  |   |       |   |  |     //
//        |  |---------------|  |     //
//        |  | |  |  |  |  | |  |     //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract XEDS is ERC1155Creator {
    constructor() ERC1155Creator("XincEds", "XEDS") {}
}