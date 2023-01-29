// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: at least unusual
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    at least unusual    //
//                        //
//                        //
////////////////////////////


contract UNUSUAL is ERC1155Creator {
    constructor() ERC1155Creator("at least unusual", "UNUSUAL") {}
}