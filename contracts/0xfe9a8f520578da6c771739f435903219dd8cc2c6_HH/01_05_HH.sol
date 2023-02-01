// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Heaven and hell test
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////
//         //
//         //
//    !    //
//         //
//         //
/////////////


contract HH is ERC1155Creator {
    constructor() ERC1155Creator("Heaven and hell test", "HH") {}
}