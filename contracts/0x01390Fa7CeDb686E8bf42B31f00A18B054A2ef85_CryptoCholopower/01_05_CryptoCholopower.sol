// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Peruvian Huacos
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                    //
//    This collection is inspired by a "Wachuma", trying to see the aura of these objects, the HUACOS are clay figures made in the year 300 AD, this project is made to make my culture known throughout the world    //
//                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CryptoCholopower is ERC1155Creator {
    constructor() ERC1155Creator("Peruvian Huacos", "CryptoCholopower") {}
}