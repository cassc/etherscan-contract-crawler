// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Thank you collection
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    benefit    //
//               //
//               //
///////////////////


contract TCA is ERC1155Creator {
    constructor() ERC1155Creator("Thank you collection", "TCA") {}
}