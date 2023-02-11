// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MinimalistMuseum
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    MINIMALISTMUSEUM    //
//                        //
//                        //
////////////////////////////


contract MM is ERC1155Creator {
    constructor() ERC1155Creator("MinimalistMuseum", "MM") {}
}