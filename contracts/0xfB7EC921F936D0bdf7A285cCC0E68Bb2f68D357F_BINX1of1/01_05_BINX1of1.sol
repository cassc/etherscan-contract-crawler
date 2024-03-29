// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Labyrinthine
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//           ,                                       //
//           \`-._           __                      //
//            \\  `-..____,.'  `.                    //
//             :`.         /    \`.                  //
//             :  )       :      : \                 //
//              ;'        '   ;  |  :                //
//              )..      .. .:.`.;  :                //
//             /::...  .:::...   ` ;                 //
//             ; _ '    __        /:\                //
//             `:o>   /\o_>      ;:. `.              //
//            `-`.__ ;   __..--- /:.   \             //
//            === \_/   ;=====_.':.     ;            //
//             ,/'`--'...`--....        ;            //
//                  ;                    ;           //
//                .'                      ;          //
//              .'                        ;          //
//            .'     ..     ,      .       ;         //
//           :       ::..  /      ;::.     |         //
//          /      `.;::.  |       ;:..    ;         //
//         :         |:.   :       ;:.    ;          //
//         :         ::     ;:..   |.    ;           //
//          :       :;      :::....|     |           //
//          /\     ,/ \      ;:::::;     ;           //
//        .:. \:..|    :     ; '.--|     ;           //
//       ::.  :''  `-.,,;     ;'   ;     ;           //
//    .-'. _.'\      / `;      \,__:      \          //
//    `---'    `----'   ;      /    \,.,,,/          //
//                       `----`              BINX    //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract BINX1of1 is ERC721Creator {
    constructor() ERC721Creator("Labyrinthine", "BINX1of1") {}
}