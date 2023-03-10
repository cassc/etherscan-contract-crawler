// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: E-Kekle Byte
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//           (  .      )                                //
//               )           (              )           //
//                     .  '   .   '  .  '  .            //
//            (    , )       (.   )  (   ',    )        //
//             .' ) ( . )    ,  ( ,     )   ( .         //
//          ). , ( .   (  ) ( , ')  .' (  ,    )        //
//         (_,) . ), ) _) _,')  (, ) '. )  ,. (' )      //
//     jpg^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^    //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract STAGE1 is ERC1155Creator {
    constructor() ERC1155Creator("E-Kekle Byte", "STAGE1") {}
}