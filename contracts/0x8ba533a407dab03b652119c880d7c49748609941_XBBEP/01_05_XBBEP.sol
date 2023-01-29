// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: XBBEP
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//    xoxo - bbep     //
//                    //
//                    //
////////////////////////


contract XBBEP is ERC1155Creator {
    constructor() ERC1155Creator("XBBEP", "XBBEP") {}
}