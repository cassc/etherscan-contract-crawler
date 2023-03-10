// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: test ama erc1155
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    testoij    //
//               //
//               //
///////////////////


contract tstst is ERC1155Creator {
    constructor() ERC1155Creator("test ama erc1155", "tstst") {}
}