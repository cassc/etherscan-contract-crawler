// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Verified Comedy - OPEN EDITION
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////
//                          //
//                          //
//                          //
//    01100111 01101101     //
//                          //
//                          //
//                          //
//////////////////////////////


contract VFUNNY is ERC1155Creator {
    constructor() ERC1155Creator("Verified Comedy - OPEN EDITION", "VFUNNY") {}
}