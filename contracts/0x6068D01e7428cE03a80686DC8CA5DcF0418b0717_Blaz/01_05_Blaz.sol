// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: blazonry
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//    blazonry is 1/1 art stored on rethereum blockchain ..     //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract Blaz is ERC1155Creator {
    constructor() ERC1155Creator("blazonry", "Blaz") {}
}