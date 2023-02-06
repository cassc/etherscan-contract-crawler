// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: COPEn EDITION
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////
//             //
//             //
//    COPEn    //
//             //
//             //
/////////////////


contract COPEn is ERC1155Creator {
    constructor() ERC1155Creator("COPEn EDITION", "COPEn") {}
}