// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Yat Fantasy Community Player Cards
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    \V/    //
//           //
//           //
///////////////


contract YATFANTASYCOMMUNITYCARDS is ERC1155Creator {
    constructor() ERC1155Creator("Yat Fantasy Community Player Cards", "YATFANTASYCOMMUNITYCARDS") {}
}