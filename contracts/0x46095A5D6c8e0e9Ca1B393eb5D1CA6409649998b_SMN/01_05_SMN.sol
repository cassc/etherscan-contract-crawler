// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shaman
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                        //
//                                                                                                                        //
//    I represent the shaman with my imagination by summoning fearsome and powerful monsters to fight negative spirits    //
//                                                                                                                        //
//                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SMN is ERC1155Creator {
    constructor() ERC1155Creator("Shaman", "SMN") {}
}