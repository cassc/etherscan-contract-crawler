// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HOLDK
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////
//             //
//             //
//    HOLDK    //
//             //
//             //
/////////////////


contract HOLDK is ERC1155Creator {
    constructor() ERC1155Creator("HOLDK", "HOLDK") {}
}