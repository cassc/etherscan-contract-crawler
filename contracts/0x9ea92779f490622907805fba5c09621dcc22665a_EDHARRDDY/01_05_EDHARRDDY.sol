// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Harrddy Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    Reject Humanity, Return to Harrddy    //
//                                          //
//                                          //
//////////////////////////////////////////////


contract EDHARRDDY is ERC1155Creator {
    constructor() ERC1155Creator("Harrddy Editions", "EDHARRDDY") {}
}