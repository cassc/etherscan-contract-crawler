// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: No Checks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    No Checks                       //
//    Open Edition                    //
//    Only while supplies last kek    //
//                                    //
//                                    //
////////////////////////////////////////


contract NC is ERC1155Creator {
    constructor() ERC1155Creator("No Checks", "NC") {}
}