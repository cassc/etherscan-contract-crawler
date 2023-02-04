// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ImagineDann
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    D A N N     //
//                //
//                //
////////////////////


contract DANN is ERC1155Creator {
    constructor() ERC1155Creator("ImagineDann", "DANN") {}
}