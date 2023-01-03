// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NicoletaTesta
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//                              //
//                              //
//                              //
//       _..._                  //
//     .'     '.                //
//    .   .-.   .      .|       //
//    |  '   '  |    .' |_      //
//    |  |   |  |  .'     |     //
//    |  |   |  | '--.  .-'     //
//    |  |   |  |    |  |       //
//    |  |   |  |    |  |       //
//    |  |   |  |    |  '.'     //
//    |  |   |  |    |   /      //
//    '--'   '--'    `'-'       //
//                              //
//                              //
//                              //
//////////////////////////////////


contract NT is ERC1155Creator {
    constructor() ERC1155Creator("NicoletaTesta", "NT") {}
}