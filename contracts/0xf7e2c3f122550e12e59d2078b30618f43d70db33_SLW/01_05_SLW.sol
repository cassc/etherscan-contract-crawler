// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SeaLightSwap
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Sealightswap    //
//                    //
//                    //
////////////////////////


contract SLW is ERC721Creator {
    constructor() ERC721Creator("SeaLightSwap", "SLW") {}
}