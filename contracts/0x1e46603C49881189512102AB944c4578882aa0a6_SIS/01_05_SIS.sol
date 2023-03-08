// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SEMINIS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//    Hello World!    //
//                    //
//                    //
////////////////////////


contract SIS is ERC1155Creator {
    constructor() ERC1155Creator("SEMINIS", "SIS") {}
}