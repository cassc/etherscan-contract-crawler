// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Noraoji Pass Genesis
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Noraoji Pass Genesis    //
//                            //
//                            //
////////////////////////////////


contract NPG is ERC1155Creator {
    constructor() ERC1155Creator("Noraoji Pass Genesis", "NPG") {}
}