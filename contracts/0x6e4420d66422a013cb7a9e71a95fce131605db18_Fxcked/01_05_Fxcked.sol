// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FXCKEDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//    FXCKEDITIONS    //
//    * * *** *       //
//       *     **     //
//     *     *   *    //
//                    //
//       *       *    //
//      *    *        //
//         *          //
//        *     *     //
//    *        *      //
//     *              //
//                    //
//          * *       //
//                    //
//                    //
////////////////////////


contract Fxcked is ERC1155Creator {
    constructor() ERC1155Creator("FXCKEDITIONS", "Fxcked") {}
}