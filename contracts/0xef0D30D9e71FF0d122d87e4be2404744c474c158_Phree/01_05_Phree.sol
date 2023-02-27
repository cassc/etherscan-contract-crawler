// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Phreedom
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    Phreedom    //
//                //
//                //
////////////////////


contract Phree is ERC1155Creator {
    constructor() ERC1155Creator("Phreedom", "Phree") {}
}