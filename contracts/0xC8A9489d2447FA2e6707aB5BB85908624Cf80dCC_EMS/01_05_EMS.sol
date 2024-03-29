// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Web3 Emission
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                                                             //
//                                                                             //
//     __        __   _    _____   _____           _         _                 //
//     \ \      / /__| |__|___ /  | ____|_ __ ___ (_)___ ___(_) ___  _ __      //
//      \ \ /\ / / _ \ '_ \ |_ \  |  _| | '_ ` _ \| / __/ __| |/ _ \| '_ \     //
//       \ V  V /  __/ |_) |__) | | |___| | | | | | \__ \__ \ | (_) | | | |    //
//        \_/\_/ \___|_.__/____/  |_____|_| |_| |_|_|___/___/_|\___/|_| |_|    //
//                                                                             //
//                                                                             //
//                                                                             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


contract EMS is ERC1155Creator {
    constructor() ERC1155Creator("Web3 Emission", "EMS") {}
}