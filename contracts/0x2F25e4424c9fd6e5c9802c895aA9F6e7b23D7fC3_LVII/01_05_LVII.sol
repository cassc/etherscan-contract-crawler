// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Super Bowl LVII
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
//                                                                                                //
//    Super Bowl LVII is a tribute to celebrate the Kansas City Chiefs vs Philadelphia Eagles     //
//                                                                                                //
//                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////


contract LVII is ERC1155Creator {
    constructor() ERC1155Creator("Super Bowl LVII", "LVII") {}
}