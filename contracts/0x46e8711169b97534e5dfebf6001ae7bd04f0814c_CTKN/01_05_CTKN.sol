// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ClaimTkn
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    CTKN    //
//            //
//            //
////////////////


contract CTKN is ERC1155Creator {
    constructor() ERC1155Creator("ClaimTkn", "CTKN") {}
}