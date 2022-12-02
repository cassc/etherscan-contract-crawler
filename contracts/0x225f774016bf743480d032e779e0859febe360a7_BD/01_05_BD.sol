// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DiDonato Studio
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    DiDonato Studio Editions    //
//                                //
//                                //
////////////////////////////////////


contract BD is ERC1155Creator {
    constructor() ERC1155Creator("DiDonato Studio", "BD") {}
}