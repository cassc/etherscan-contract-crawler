// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MR. Midnight
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    Mr. Midnight, by Cod Mas    //
//                                //
//                                //
////////////////////////////////////


contract MRM is ERC1155Creator {
    constructor() ERC1155Creator("MR. Midnight", "MRM") {}
}