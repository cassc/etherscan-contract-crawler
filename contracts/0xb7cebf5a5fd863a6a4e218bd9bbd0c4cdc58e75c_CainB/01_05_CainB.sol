// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cain Beaudoin Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    Thanks for becoming      //
//    one of my collectors,    //
//    Cain Beaudoin            //
//                             //
//                             //
//                             //
/////////////////////////////////


contract CainB is ERC1155Creator {
    constructor() ERC1155Creator("Cain Beaudoin Editions", "CainB") {}
}