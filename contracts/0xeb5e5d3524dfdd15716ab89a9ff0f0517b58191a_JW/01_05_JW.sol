// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jonathan Wolfe Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//                                                                   //
//                                                                   //
//                 jjjj                                              //
//                j::::j                                             //
//                 jjjj                                              //
//                                                                   //
//               jjjjjjjwwwwwww           wwwww           wwwwwww    //
//               j:::::j w:::::w         w:::::w         w:::::w     //
//                j::::j  w:::::w       w:::::::w       w:::::w      //
//                j::::j   w:::::w     w:::::::::w     w:::::w       //
//                j::::j    w:::::w   w:::::w:::::w   w:::::w        //
//                j::::j     w:::::w w:::::w w:::::w w:::::w         //
//                j::::j      w:::::w:::::w   w:::::w:::::w          //
//                j::::j       w:::::::::w     w:::::::::w           //
//                j::::j        w:::::::w       w:::::::w            //
//                j::::j         w:::::w         w:::::w             //
//                j::::j          w:::w           w:::w              //
//                j::::j           www             www               //
//                j::::j                                             //
//      jjjj      j::::j                                             //
//     j::::jj   j:::::j                                             //
//     j::::::jjj::::::j                                             //
//      jj::::::::::::j                                              //
//        jjj::::::jjj                                               //
//           jjjjjj                                                  //
//                                                                   //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract JW is ERC1155Creator {
    constructor() ERC1155Creator("Jonathan Wolfe Editions", "JW") {}
}