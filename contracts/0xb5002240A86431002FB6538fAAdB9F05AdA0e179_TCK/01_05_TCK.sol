// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cold Keys
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    TCK LOVE    //
//                //
//                //
////////////////////


contract TCK is ERC1155Creator {
    constructor() ERC1155Creator("Cold Keys", "TCK") {}
}