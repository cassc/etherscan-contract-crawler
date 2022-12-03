// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MNiML vXYZ
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                    __     //
//     |\/| |\ | o |\/| |       \/ \_/ /     //
//     |  | | \| | |  | |_   \/ /\  | /_     //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract vXYZ is ERC1155Creator {
    constructor() ERC1155Creator("MNiML vXYZ", "vXYZ") {}
}