// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Paintings
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//          m   ~)                   v ~)                                   //
//                |             o    (_/^\               o  (_/^\           //
//               \ /          *-|\    /|~|\    w  ~)   x-|\_./|~|\          //
//              -   -          .|_\.-/ / / |'.,o..(_/^\.-|_\/ / / |'-._.    //
//               / \          .              @-|\  /|~|\                    //
//                |       _.-'                 |_\/ / / |                   //
//                      .'                                                  //
//                  _.-'                                                    //
//    -._      __.-'        Andrew Newman & ejm97                           //
//       ''-.-'                                                             //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


contract PS is ERC721Creator {
    constructor() ERC721Creator("Paintings", "PS") {}
}