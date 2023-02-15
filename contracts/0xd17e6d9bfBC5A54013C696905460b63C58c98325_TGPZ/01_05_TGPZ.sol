// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Greatest Pizza To Ever Exist
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//    Hurric4n3Ike    //
//                    //
//                    //
////////////////////////


contract TGPZ is ERC1155Creator {
    constructor() ERC1155Creator("The Greatest Pizza To Ever Exist", "TGPZ") {}
}