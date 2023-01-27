// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Staring Faces
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//                       __ooooooooo__                       //
//                  oOOOOOOOOOOOOOOOOOOOOOo                  //
//              oOOOOOOOOOOOOOOOOOOOOOOOOOOOOOo              //
//           oOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOo           //
//         oOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOo         //
//       oOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOo       //
//      oOOOOOOOOOOO*  *OOOOOOOOOOOOOO*  *OOOOOOOOOOOOo      //
//     oOOOOOOOOOOO      OOOOOOOOOOOO      OOOOOOOOOOOOo     //
//     oOOOOOOOOOOOOo  oOOOOOOOOOOOOOOo  oOOOOOOOOOOOOOo     //
//    oOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOo    //
//    oOOOO     OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO     OOOOo    //
//    oOOOOOO OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO OOOOOOo    //
//     *OOOOO  OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO  OOOOO*     //
//     *OOOOOO  *OOOOOOOOOOOOOOOOOOOOOOOOOOOOO*  OOOOOO*     //
//      *OOOOOO  *OOOOOOOOOOOOOOOOOOOOOOOOOOO*  OOOOOO*      //
//       *OOOOOOo  *OOOOOOOOOOOOOOOOOOOOOOO*  oOOOOOO*       //
//         *OOOOOOOo  *OOOOOOOOOOOOOOOOO*  oOOOOOOO*         //
//           *OOOOOOOOo  *OOOOOOOOOOO*  oOOOOOOOO*           //
//              *OOOOOOOOo           oOOOOOOOO*              //
//                  *OOOOOOOOOOOOOOOOOOOOO*                  //
//                       ""ooooooooo""                       //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract FACES is ERC721Creator {
    constructor() ERC721Creator("Staring Faces", "FACES") {}
}