// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JANKx
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    JANK XYZ: JANK X    //
//                        //
//                        //
////////////////////////////


contract JANKx is ERC1155Creator {
    constructor() ERC1155Creator("JANKx", "JANKx") {}
}