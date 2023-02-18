// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ONEOONES
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    1/1    //
//           //
//           //
///////////////


contract ONEOONE is ERC721Creator {
    constructor() ERC721Creator("ONEOONES", "ONEOONE") {}
}