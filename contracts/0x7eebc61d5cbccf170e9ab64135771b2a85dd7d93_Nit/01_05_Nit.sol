// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nitnit
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//     __ _  __  ____  __ _  __  ____     //
//    (  ( \(  )(_  _)(  ( \(  )(_  _)    //
//    /    / )(   )(  /    / )(   )(      //
//    \_)__)(__) (__) \_)__)(__) (__)     //
//                                        //
//                                        //
////////////////////////////////////////////


contract Nit is ERC1155Creator {
    constructor() ERC1155Creator("Nitnit", "Nit") {}
}