// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: magnetismo's editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                                                                                              //
//                                                                                              //
//                                    ....                                                      //
//            ^!77^. .              ..     ....                                                 //
//           JBBBBBP:  ~YYJ~:...  ..          ...                                               //
//          .BBBBBBBB:!BBBBBG^  ..^             ..                                              //
//          :BBBBBBBBBBBBBBBBB      ..           ^                                              //
//           PBBBBBBBBBBBBBBBB.       ..         :                                              //
//           :GBBBBBBBBBBBBBB~          :.    ...                                               //
//            .JGBBBBBBBBBP5^.......     :. ..                                                  //
//              ^:~?5GG5!. :        ..    :.                                                    //
//              :    ^.:   ..         ......                                                    //
//            :.     : :.   ^                                                                   //
//            ....   :. :.  ....                                                                //
//                       ......:                                                                //
//                                                                                              //
//     .-.-. .-.-. .-.-. .-.-. .-.-. .-.-. .-.-. .-.-.                                          //
//    '. e )'. d )'. i )'. t )'. i )'. o )'. n )'. s )                                          //
//      ).'   ).'   ).'   ).'   ).'   ).'   ).'   ).'                                           //
//                                                    by magnetismo                             //
//                                                                                              //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////


contract MGED is ERC1155Creator {
    constructor() ERC1155Creator("magnetismo's editions", "MGED") {}
}