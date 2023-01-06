// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SATVRN DAILY
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    2023    //
//            //
//            //
////////////////


contract STVRNDLY is ERC1155Creator {
    constructor() ERC1155Creator("SATVRN DAILY", "STVRNDLY") {}
}