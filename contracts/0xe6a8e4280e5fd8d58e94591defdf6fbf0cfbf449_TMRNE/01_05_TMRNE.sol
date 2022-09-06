// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Most Random NFTs Ever
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//    | | |||    //
//    |||  |     //
//    | | |||    //
//               //
//               //
//               //
///////////////////


contract TMRNE is ERC721Creator {
    constructor() ERC721Creator("The Most Random NFTs Ever", "TMRNE") {}
}