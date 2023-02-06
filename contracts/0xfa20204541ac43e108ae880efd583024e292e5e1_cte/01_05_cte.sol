// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: c0des - Mixed Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    c0des - Mix Editions    //
//                            //
//    P r a x i s .           //
//                            //
//                            //
////////////////////////////////


contract cte is ERC1155Creator {
    constructor() ERC1155Creator("c0des - Mixed Editions", "cte") {}
}