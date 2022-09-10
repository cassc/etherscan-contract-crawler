// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RinkeTestERC721
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    rterc721    //
//                //
//                //
////////////////////


contract RTERC721 is ERC721Creator {
    constructor() ERC721Creator("RinkeTestERC721", "RTERC721") {}
}