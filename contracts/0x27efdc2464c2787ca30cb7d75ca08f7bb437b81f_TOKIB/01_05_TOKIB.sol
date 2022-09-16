// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TOKIPHY-BETA-TESTING
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//                                                                         //
//      _____    ___    _  __  ___   ____    _   _  __   __                //
//     |_   _|  / _ \  | |/ / |_ _| |  _ \  | | | | \ \ / /                //
//       | |   | | | | | ' /   | |  | |_) | | |_| |  \ V /                 //
//       | |   | |_| | | . \   | |  |  __/  |  _  |   | |                  //
//       |_|    \___/  |_|\_\ |___| |_|     |_| |_|   |_|  beta testing    //
//                                                                         //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract TOKIB is ERC721Creator {
    constructor() ERC721Creator("TOKIPHY-BETA-TESTING", "TOKIB") {}
}