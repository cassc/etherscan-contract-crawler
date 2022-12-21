// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Beyond Crypto (Hex6)
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    HEX6 to mint Superbug X in 2023.    //
//                                        //
//                                        //
////////////////////////////////////////////


contract HEX6 is ERC721Creator {
    constructor() ERC721Creator("Beyond Crypto (Hex6)", "HEX6") {}
}