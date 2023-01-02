// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JANKy
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    JANK XYZ: JANK Y    //
//                        //
//                        //
////////////////////////////


contract JANKy is ERC1155Creator {
    constructor() ERC1155Creator("JANKy", "JANKy") {}
}