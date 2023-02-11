// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bittensor Checks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//                                                        //
//    █▄▄ █ ▀█▀ ▀█▀ █▀▀ █▄░█ █▀ █▀█ █▀█                   //
//    █▄█ █ ░█░ ░█░ ██▄ █░▀█ ▄█ █▄█ █▀▄                   //
//                                                        //
//    █░█ █▀█ █░░ █▀▄ █▀▀ █▀█ █▀   █▀▀ █░█ █▀▀ █▀▀ █▄▀    //
//    █▀█ █▄█ █▄▄ █▄▀ ██▄ █▀▄ ▄█   █▄▄ █▀█ ██▄ █▄▄ █░█    //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract TAOCHECKS is ERC1155Creator {
    constructor() ERC1155Creator("Bittensor Checks", "TAOCHECKS") {}
}