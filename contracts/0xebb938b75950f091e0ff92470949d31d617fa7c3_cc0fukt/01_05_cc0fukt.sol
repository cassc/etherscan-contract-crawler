// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: cc0fukt
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////
//         //
//         //
//    f    //
//         //
//         //
/////////////


contract cc0fukt is ERC1155Creator {
    constructor() ERC1155Creator("cc0fukt", "cc0fukt") {}
}