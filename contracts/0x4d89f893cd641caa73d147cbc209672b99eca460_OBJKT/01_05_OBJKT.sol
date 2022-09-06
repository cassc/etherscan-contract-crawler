// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Objectively Yours
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    [o]    //
//           //
//           //
///////////////


contract OBJKT is ERC721Creator {
    constructor() ERC721Creator("Objectively Yours", "OBJKT") {}
}