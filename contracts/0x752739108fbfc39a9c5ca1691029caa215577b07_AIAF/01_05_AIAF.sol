// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AI artificial flowers
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//               .-(   \  /   )-.     //
//             /   '..oOOo..'   \     //
//     ,       \.--.oOOOOOOo.--./     //
//     |\  ,   (   :oNatalieo:   )    //
//    _\.\/|   /'--'oOShauOo'--'\     //
//    '-.. ;/| \   .''oOOo''.   /     //
//    .--`'. :/|'-(   /  \   )-'      //
//     '--. `. / //'-'.__.'-;         //
//       `'-,_';//      ,  /|         //
//            '((       |\/./_        //
//              \\  . |\; ..-'        //
//               \\ |\: .'`--.        //
//                \\, .' .--'         //
//                 ))'_,-'`           //
//           AF  //-'                 //
//               //                   //
//              //                    //
//             |/                     //
//                                    //
//                                    //
////////////////////////////////////////


contract AIAF is ERC721Creator {
    constructor() ERC721Creator("AI artificial flowers", "AIAF") {}
}