// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DaWe1 Editionz
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    dAwEone    //
//               //
//               //
///////////////////


contract DWE is ERC1155Creator {
    constructor() ERC1155Creator("DaWe1 Editionz", "DWE") {}
}