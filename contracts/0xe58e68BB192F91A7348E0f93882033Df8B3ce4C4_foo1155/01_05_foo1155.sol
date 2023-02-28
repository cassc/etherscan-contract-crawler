// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Foo1155
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//     _________         //
//    < foo1155 >        //
//     ---------         //
//       \               //
//        \              //
//            .--.       //
//           |o_o |      //
//           |:_/ |      //
//          //   \ \     //
//         (|     | )    //
//        /'\_   _/`\    //
//        \___)=(___/    //
//                       //
//                       //
///////////////////////////


contract foo1155 is ERC1155Creator {
    constructor() ERC1155Creator("Foo1155", "foo1155") {}
}