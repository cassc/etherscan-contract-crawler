// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PASTAPEEPS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//    X0X0X0X0X0X0XX0X0X0X0X0XX0X0X0XX0X0X0XX0X0X0XX0X0X0XX0X0X0    //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract BRN is ERC1155Creator {
    constructor() ERC1155Creator("PASTAPEEPS", "BRN") {}
}