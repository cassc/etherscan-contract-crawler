// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Message 2006 A.D
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//                                                                           //
//     ___                                   _                               //
//      | |_   _   |\/|     _ _|_  _  ._    |_)  _      _   _. |  _   _|     //
//      | | | (/_  |  | \/ _>  |_ (/_ | \/  | \ (/_ \/ (/_ (_| | (/_ (_|     //
//                      /               /                                    //
//                                                                           //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


contract MM7x7 is ERC1155Creator {
    constructor() ERC1155Creator("The Message 2006 A.D", "MM7x7") {}
}