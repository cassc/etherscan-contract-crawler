// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bloody Heart
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////
//             //
//             //
//    FEB14    //
//             //
//             //
/////////////////


contract FEB14 is ERC1155Creator {
    constructor() ERC1155Creator("Bloody Heart", "FEB14") {}
}