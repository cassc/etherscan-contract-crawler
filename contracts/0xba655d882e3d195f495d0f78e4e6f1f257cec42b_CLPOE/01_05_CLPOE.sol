// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CLAPIS OE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    0000    //
//            //
//            //
////////////////


contract CLPOE is ERC1155Creator {
    constructor() ERC1155Creator("CLAPIS OE", "CLPOE") {}
}