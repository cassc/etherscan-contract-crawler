// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CHIBI PASS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//                                                              //
//      ___  _   _  ____  ____  ____  ____   __    ___  ___     //
//     / __)( )_( )(_  _)(  _ \(_  _)(  _ \ /__\  / __)/ __)    //
//    ( (__  ) _ (  _)(_  ) _ < _)(_  )___//(__)\ \__ \\__ \    //
//     \___)(_) (_)(____)(____/(____)(__) (__)(__)(___/(___/    //
//                                                              //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract CHIBIPASS is ERC1155Creator {
    constructor() ERC1155Creator("CHIBI PASS", "CHIBIPASS") {}
}