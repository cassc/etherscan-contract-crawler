// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Waiting for ...
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    «Waiting for …»              //
//    copyright by flavio leone    //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract WF is ERC1155Creator {
    constructor() ERC1155Creator("Waiting for ...", "WF") {}
}