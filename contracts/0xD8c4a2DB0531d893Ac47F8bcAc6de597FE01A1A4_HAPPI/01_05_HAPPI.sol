// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HAPPICAKE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
//                            H A P P I C A K E                            //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract HAPPI is ERC1155Creator {
    constructor() ERC1155Creator("HAPPICAKE", "HAPPI") {}
}