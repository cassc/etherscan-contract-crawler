// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks by Capies
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    lol cap    //
//               //
//               //
///////////////////


contract CAP is ERC1155Creator {
    constructor() ERC1155Creator("Checks by Capies", "CAP") {}
}