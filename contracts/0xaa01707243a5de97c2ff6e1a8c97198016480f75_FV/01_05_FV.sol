// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Future Visions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    Kaps    //
//            //
//            //
////////////////


contract FV is ERC1155Creator {
    constructor() ERC1155Creator("Future Visions", "FV") {}
}