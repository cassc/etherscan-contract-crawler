// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lascaux
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    Are we really this fukt?    //
//                                //
//                                //
////////////////////////////////////


contract MXFK is ERC1155Creator {
    constructor() ERC1155Creator("Lascaux", "MXFK") {}
}