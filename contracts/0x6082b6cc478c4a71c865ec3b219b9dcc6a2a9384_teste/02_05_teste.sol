// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: test-editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    test-editions    //
//                     //
//                     //
/////////////////////////


contract teste is ERC1155Creator {
    constructor() ERC1155Creator("test-editions", "teste") {}
}