// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Clutch Kickers
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//    Clutch kickers    //
//                      //
//                      //
//////////////////////////


contract Ck is ERC1155Creator {
    constructor() ERC1155Creator("Clutch Kickers", "Ck") {}
}