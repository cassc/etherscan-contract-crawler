// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HappyBeany Open Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//     _  _   __   ____  ____  _  _    ____  ____   __   __ _  _  _     //
//    / )( \ / _\ (  _ \(  _ \( \/ )  (  _ \(  __) / _\ (  ( \( \/ )    //
//    ) __ (/    \ ) __/ ) __/ )  /    ) _ ( ) _) /    \/    / )  /     //
//    \_)(_/\_/\_/(__)  (__)  (__/    (____/(____)\_/\_/\_)__)(__/      //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract OEHB is ERC1155Creator {
    constructor() ERC1155Creator("HappyBeany Open Editions", "OEHB") {}
}