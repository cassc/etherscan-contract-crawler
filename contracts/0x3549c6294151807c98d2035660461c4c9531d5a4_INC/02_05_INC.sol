// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: INCARNATEs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//    inferno    //
//               //
//               //
///////////////////


contract INC is ERC721Creator {
    constructor() ERC721Creator("INCARNATEs", "INC") {}
}