// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: artenpreneur
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//    GM_SERIES_COLLECTION_NEW_DAY_NEW_GM_BY_ARTENPRENEUR    //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract ARTEN is ERC1155Creator {
    constructor() ERC1155Creator("artenpreneur", "ARTEN") {}
}