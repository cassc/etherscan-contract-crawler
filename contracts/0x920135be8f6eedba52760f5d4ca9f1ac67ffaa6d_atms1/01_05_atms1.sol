// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: auru_test_man_contract_name_001
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    auru_test_man_asciimark_001    //
//                                   //
//                                   //
///////////////////////////////////////


contract atms1 is ERC1155Creator {
    constructor() ERC1155Creator("auru_test_man_contract_name_001", "atms1") {}
}