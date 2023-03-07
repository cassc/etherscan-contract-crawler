// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Yat Fantasy Hype Club
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    \V/    //
//           //
//           //
///////////////


contract YATFANTASYHYPECLUB is ERC1155Creator {
    constructor() ERC1155Creator("Yat Fantasy Hype Club", "YATFANTASYHYPECLUB") {}
}