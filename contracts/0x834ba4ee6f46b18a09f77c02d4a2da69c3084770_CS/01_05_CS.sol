// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cold Spicy
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    CS CS CS    //
//                //
//                //
////////////////////


contract CS is ERC1155Creator {
    constructor() ERC1155Creator("Cold Spicy", "CS") {}
}