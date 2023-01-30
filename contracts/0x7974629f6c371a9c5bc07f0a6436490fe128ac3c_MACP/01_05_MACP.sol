// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MejikaAkira Chronicles Pass
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    No utilities     //
//                     //
//                     //
/////////////////////////


contract MACP is ERC1155Creator {
    constructor() ERC1155Creator("MejikaAkira Chronicles Pass", "MACP") {}
}