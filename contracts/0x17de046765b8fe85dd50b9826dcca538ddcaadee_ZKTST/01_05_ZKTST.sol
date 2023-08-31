// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Zak Goerli 1155 Test
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                              //
//    _________  ___    ______  ___   _   __    //
//    |  ___|  \/  |_  |___  / / _ \ | | / /    //
//    | |_  | .  . (_)    / / / /_\ \| |/ /     //
//    |  _| | |\/| |     / /  |  _  ||    \     //
//    | |   | |  | |_  ./ /___| | | || |\  \    //
//    \_|   \_|  |_(_) \_____/\_| |_/\_| \_/    //
//                                              //
//                                              //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract ZKTST is ERC1155Creator {
    constructor() ERC1155Creator("Zak Goerli 1155 Test", "ZKTST") {}
}