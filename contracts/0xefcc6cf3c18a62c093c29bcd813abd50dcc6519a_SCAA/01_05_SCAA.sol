// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SCA Airdrops
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                           //
//                                                                                                                                                                           //
//    Surreal Creations by azee is a collection minted on an ERC721 Contract . SCA Airdrops are an ERC 1155 Edition tokens which are airdropped to SCA Edition 2 Holders     //
//                                                                                                                                                                           //
//                                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SCAA is ERC1155Creator {
    constructor() ERC1155Creator() {}
}