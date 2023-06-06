// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Resurgence
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    Kristina Savelyeva - edition    //
//                                    //
//                                    //
////////////////////////////////////////


contract KSE is ERC1155Creator {
    constructor() ERC1155Creator("Resurgence", "KSE") {}
}