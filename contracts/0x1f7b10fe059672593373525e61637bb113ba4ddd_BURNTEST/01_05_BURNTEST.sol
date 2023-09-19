// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Burn Contract
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//    This is a test burn contract to redeem OE's for a Membership pass    //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract BURNTEST is ERC1155Creator {
    constructor() ERC1155Creator("Burn Contract", "BURNTEST") {}
}