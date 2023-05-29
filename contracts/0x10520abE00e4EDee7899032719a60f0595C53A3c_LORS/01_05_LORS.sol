// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LORS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//    I'm a nobody    //
//                    //
//                    //
////////////////////////


contract LORS is ERC1155Creator {
    constructor() ERC1155Creator("LORS", "LORS") {}
}