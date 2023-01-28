// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Natsumi
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    Natsumi    //
//               //
//               //
///////////////////


contract NSM is ERC1155Creator {
    constructor() ERC1155Creator("Natsumi", "NSM") {}
}