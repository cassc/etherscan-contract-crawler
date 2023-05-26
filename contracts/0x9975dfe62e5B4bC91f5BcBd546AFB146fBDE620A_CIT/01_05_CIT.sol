// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CI-Tester
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    CI-Tester    //
//                 //
//                 //
/////////////////////


contract CIT is ERC1155Creator {
    constructor() ERC1155Creator("CI-Tester", "CIT") {}
}