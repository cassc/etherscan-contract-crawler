// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MW
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//                         //
//       *                 //
//     (  `   (  (         //
//     )\))(  )\))(   '    //
//    ((_)()\((_)()\ )     //
//    (_()((_)(())\_)()    //
//    |  \/  \ \((_)/ /    //
//    | |\/| |\ \/\/ /     //
//    |_|  |_| \_/\_/      //
//                         //
//                         //
//                         //
//                         //
/////////////////////////////


contract MW is ERC1155Creator {
    constructor() ERC1155Creator("MW", "MW") {}
}