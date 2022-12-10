// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dad?
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//    Daddy Issues    //
//                    //
//                    //
////////////////////////


contract DAD is ERC1155Creator {
    constructor() ERC1155Creator("Dad?", "DAD") {}
}