// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Beeple XXV: The Millionth Day
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    BEEPLEXXV    //
//    XXVXXVXXV    //
//                 //
//                 //
/////////////////////


contract BeepleXXV is ERC1155Creator {
    constructor() ERC1155Creator("Beeple XXV: The Millionth Day", "BeepleXXV") {}
}