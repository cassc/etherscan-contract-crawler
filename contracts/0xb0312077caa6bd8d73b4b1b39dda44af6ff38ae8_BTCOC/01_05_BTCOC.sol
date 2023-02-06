// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bitcoin Old Coins
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//        ___ _____ ___    ___  _    _    ___     _                                    //
//       | _ )_   _/ __|  / _ \| |__| |  / __|___(_)_ _  ___                           //
//       | _ \ | || (__  | (_) | / _` | | (__/ _ \ | ' \(_-<                           //
//       |___/ |_| \___|  \___/|_\__,_|  \___\___/_|_||_/__/                           //
//                                              by OxO_Arts_                           //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract BTCOC is ERC721Creator {
    constructor() ERC721Creator("Bitcoin Old Coins", "BTCOC") {}
}