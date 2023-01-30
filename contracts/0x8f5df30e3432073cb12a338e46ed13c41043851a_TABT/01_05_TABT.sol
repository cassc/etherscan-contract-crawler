// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Archives by TEJI
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    The Archives by TEJI.    //
//                             //
//                             //
/////////////////////////////////


contract TABT is ERC1155Creator {
    constructor() ERC1155Creator("The Archives by TEJI", "TABT") {}
}