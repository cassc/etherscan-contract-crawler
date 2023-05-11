// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Web3 Fam 2023
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    Fam2023    //
//               //
//               //
///////////////////


contract Fam2023 is ERC1155Creator {
    constructor() ERC1155Creator("Web3 Fam 2023", "Fam2023") {}
}