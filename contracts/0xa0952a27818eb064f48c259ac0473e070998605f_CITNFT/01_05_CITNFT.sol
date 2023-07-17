// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Citadel WOOL Reserve NFT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//    ▀▀█▀▀ ▒█░▒█ ▒█▀▀▀                           //
//    ░▒█░░ ▒█▀▀█ ▒█▀▀▀                           //
//    ░▒█░░ ▒█░▒█ ▒█▄▄▄                           //
//                                                //
//    ▒█▀▀█ ▀█▀ ▀▀█▀▀ ░█▀▀█ ▒█▀▀▄ ▒█▀▀▀ ▒█░░░     //
//    ▒█░░░ ▒█░ ░▒█░░ ▒█▄▄█ ▒█░▒█ ▒█▀▀▀ ▒█░░░     //
//    ▒█▄▄█ ▄█▄ ░▒█░░ ▒█░▒█ ▒█▄▄▀ ▒█▄▄▄ ▒█▄▄█     //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract CITNFT is ERC721Creator {
    constructor() ERC721Creator("The Citadel WOOL Reserve NFT", "CITNFT") {}
}