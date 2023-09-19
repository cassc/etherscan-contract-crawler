// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks X Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    Checks X Edition    //
//                        //
//                        //
////////////////////////////


contract CXE is ERC1155Creator {
    constructor() ERC1155Creator("Checks X Edition", "CXE") {}
}