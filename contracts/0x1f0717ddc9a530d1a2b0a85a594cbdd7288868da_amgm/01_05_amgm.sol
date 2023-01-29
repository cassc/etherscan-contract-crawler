// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: am gm
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//    a gm from am    //
//                    //
//                    //
////////////////////////


contract amgm is ERC1155Creator {
    constructor() ERC1155Creator("am gm", "amgm") {}
}