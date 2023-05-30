// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CSFunFictionAwards
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//     The CSFunFictionAwards NFT contract represents a collection of unique awards    //
//    given to fans and collectors for their contributions and engagement              //
//    in the CreateSysters FunFiction ecosystem.                                       //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract CSAs is ERC1155Creator {
    constructor() ERC1155Creator("CSFunFictionAwards", "CSAs") {}
}