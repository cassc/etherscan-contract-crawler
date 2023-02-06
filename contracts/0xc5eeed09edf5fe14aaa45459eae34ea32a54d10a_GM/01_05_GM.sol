// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WAGMI
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                                                                         //
//    Bot test, potential bot drainer. Been seeing how often frens get botted on their     //
//    drops, so here's a drop just for the bots. WAGMI. Sunday dog days.                   //
//                                                                                         //
//    Eth pump. BTC. secret. doge coin. alt coin. burn mechanic. mystery. famous. lol.     //
//    gm gm gm gm gm gm gm gm gm gm gm gm gm gm gm gm gm gm gm gm gm gm gm gm gm gm gm.    //
//                                                                                         //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////


contract GM is ERC1155Creator {
    constructor() ERC1155Creator("WAGMI", "GM") {}
}