// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ceydaizm
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                       //
//                                                                                                                       //
//    Collect 3 for the "burn & redeen" event  "meeting with collectors" has been released  you can burn your tokens.    //
//    This collection is the first of three collection series.                                                           //
//    These are completely handmade and belong to me, please stay tuned to my social media accounts for updates.         //
//    https://twitter.com/ceydazm                                                                                        //
//                                                                                                                       //
//                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ceydazm is ERC1155Creator {
    constructor() ERC1155Creator("Ceydaizm", "ceydazm") {}
}