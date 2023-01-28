// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Weirdly
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    weirdly by Just Go Go    //
//                             //
//                             //
/////////////////////////////////


contract WDLY is ERC1155Creator {
    constructor() ERC1155Creator("Weirdly", "WDLY") {}
}