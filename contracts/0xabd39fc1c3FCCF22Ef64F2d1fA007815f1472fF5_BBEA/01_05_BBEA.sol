// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BOUBOY EDITION
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    Welcome to my dream , Bouboy edition art    //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract BBEA is ERC1155Creator {
    constructor() ERC1155Creator("BOUBOY EDITION", "BBEA") {}
}