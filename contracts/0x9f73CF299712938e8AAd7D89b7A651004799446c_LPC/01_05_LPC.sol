// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: COME AND TAKE IT - LEDGER PEPE CHECKS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//    COME AND TAKE IT - LEDGER PEPE CHECKS EDITION    //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract LPC is ERC1155Creator {
    constructor() ERC1155Creator("COME AND TAKE IT - LEDGER PEPE CHECKS", "LPC") {}
}