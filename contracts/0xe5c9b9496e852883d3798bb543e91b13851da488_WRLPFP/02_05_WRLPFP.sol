// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PFP
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    WRL    //
//           //
//           //
///////////////


contract WRLPFP is ERC721Creator {
    constructor() ERC721Creator("PFP", "WRLPFP") {}
}