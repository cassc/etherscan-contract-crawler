// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Burnt Apes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//    A collection of burnt Apes, now owned by the streets    //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract BURN is ERC1155Creator {
    constructor() ERC1155Creator("Burnt Apes", "BURN") {}
}