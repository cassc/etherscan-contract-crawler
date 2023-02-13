// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions - Jenna Dixon
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//     +-+-+-+    //
//     |E|J|D|    //
//     +-+-+-+    //
//                //
//                //
////////////////////


contract EJD is ERC1155Creator {
    constructor() ERC1155Creator("Editions - Jenna Dixon", "EJD") {}
}