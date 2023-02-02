// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Interface
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//    Wonder..is AI able to think on it's own? What have i discovered?     //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract INT is ERC1155Creator {
    constructor() ERC1155Creator("Interface", "INT") {}
}