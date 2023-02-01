// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: しじみんタウン
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    しじみん    //
//    の       //
//    パンツ     //
//            //
//            //
////////////////


contract SZP is ERC1155Creator {
    constructor() ERC1155Creator(unicode"しじみんタウン", "SZP") {}
}