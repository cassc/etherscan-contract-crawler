// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alterlier Limited Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//      _    ____                    //
//     /_| /  /  /'_  _  '_/_ _/     //
//    (  |(__(  (///)//)/ /(-(/      //
//                                   //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract ALTlimited is ERC1155Creator {
    constructor() ERC1155Creator("Alterlier Limited Editions", "ALTlimited") {}
}