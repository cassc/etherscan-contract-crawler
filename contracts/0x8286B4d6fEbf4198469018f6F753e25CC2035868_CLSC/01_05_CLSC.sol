// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Faceman Classics
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//    Early Faceman songs available for ownership via Ethereum.             //
//    These songs were made and/or released between the years 2006-2011.    //
//    All Rights Reserved by MC Faceman                                     //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


contract CLSC is ERC1155Creator {
    constructor() ERC1155Creator() {}
}