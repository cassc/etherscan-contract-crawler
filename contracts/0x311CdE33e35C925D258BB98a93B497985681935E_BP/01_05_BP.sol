// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Beast Pepe
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                                                                      //
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^_______^^^^^^^^^^    //
//                                                                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////


contract BP is ERC1155Creator {
    constructor() ERC1155Creator("Beast Pepe", "BP") {}
}