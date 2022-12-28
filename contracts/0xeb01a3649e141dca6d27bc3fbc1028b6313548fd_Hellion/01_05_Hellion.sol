// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hellion
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    Hellion    //
//               //
//               //
///////////////////


contract Hellion is ERC721Creator {
    constructor() ERC721Creator("Hellion", "Hellion") {}
}