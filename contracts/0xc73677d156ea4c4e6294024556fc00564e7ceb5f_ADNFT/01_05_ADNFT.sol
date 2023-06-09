// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: After Dark NFTs
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//                                                                                          //
//    01000001 01100110 01110100 01100101 01110010  01000100 01100001 01110010 01101011     //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract ADNFT is ERC1155Creator {
    constructor() ERC1155Creator("After Dark NFTs", "ADNFT") {}
}