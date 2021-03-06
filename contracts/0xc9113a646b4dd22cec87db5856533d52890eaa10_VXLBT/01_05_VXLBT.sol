// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VoxelBits
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                     //
//                                                                                                     //
//                                                                                                     //
//                                                                                                     //
//                                                                                                     //
//                                                 ,--,       ,---,.            ___                    //
//           ,---.                               ,--.'|     ,'  .'  \  ,--,   ,--.'|_                  //
//          /__./|   ,---.                       |  | :   ,---.' .' |,--.'|   |  | :,'                 //
//     ,---.;  ; |  '   ,'\ ,--,  ,--,           :  : '   |   |  |: ||  |,    :  : ' :  .--.--.        //
//    /___/ \  | | /   /   ||'. \/ .`|    ,---.  |  ' |   :   :  :  /`--'_  .;__,'  /  /  /    '       //
//    \   ;  \ ' |.   ; ,. :'  \/  / ;   /     \ '  | |   :   |    ; ,' ,'| |  |   |  |  :  /`./       //
//     \   \  \: |'   | |: : \  \.' /   /    /  ||  | :   |   :     \'  | | :__,'| :  |  :  ;_         //
//      ;   \  ' .'   | .; :  \  ;  ;  .    ' / |'  : |__ |   |   . ||  | :   '  : |__ \  \    `.      //
//       \   \   '|   :    | / \  \  \ '   ;   /||  | '.'|'   :  '; |'  : |__ |  | '.'| `----.   \     //
//        \   `  ; \   \  /./__;   ;  \'   |  / |;  :    ;|   |  | ; |  | '.'|;  :    ;/  /`--'  /     //
//         :   \ |  `----' |   :/\  \ ;|   :    ||  ,   / |   :   /  ;  :    ;|  ,   /'--'.     /      //
//          '---"          `---'  `--`  \   \  /  ---`-'  |   | ,'   |  ,   /  ---`-'   `--'---'       //
//                                       `----'           `----'      ---`-'                           //
//                                                                                                     //
//                                                                                                     //
//                                                                                                     //
//                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VXLBT is ERC721Creator {
    constructor() ERC721Creator("VoxelBits", "VXLBT") {}
}