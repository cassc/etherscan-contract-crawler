// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Decuration I
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                           //
//                                                                                           //
//    The first Decurator Council. Curating the Most Valuable Galleries in the Decaverse.    //
//                                                                                           //
//                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////


contract DCI is ERC1155Creator {
    constructor() ERC1155Creator("Decuration I", "DCI") {}
}