// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FC4
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    FC4    //
//           //
//           //
///////////////


contract FC4 is ERC1155Creator {
    constructor() ERC1155Creator("FC4", "FC4") {}
}