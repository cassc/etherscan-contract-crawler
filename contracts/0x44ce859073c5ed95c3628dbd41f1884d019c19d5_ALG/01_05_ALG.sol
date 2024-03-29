// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alice in editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                  ,.,   '               ,.  '                 ,.-·^*ª'` ·,                  //
//                  ;´   '· .,            /   ';\              .·´ ,·'´:¯'`·,  '\‘            //
//                .´  .-,    ';\        ,'   ,'::'\           ,´  ,'\:::::::::\,.·\'          //
//               /   /:\:';   ;:'\'     ,'    ;:::';'         /   /:::\;·'´¯'`·;\:::\°        //
//             ,'  ,'::::'\';  ;::';     ';   ,':::;'         ;   ;:::;'          '\;:·´      //
//         ,.-·'  '·~^*'´¨,  ';::;     ;  ,':::;' '        ';   ;::/      ,·´¯';  °           //
//         ':,  ,·:²*´¨¯'`;  ;::';    ,'  ,'::;'           ';   '·;'   ,.·´,    ;'\           //
//         ,'  / \::::::::';  ;::';    ;  ';_:,.-·´';\‘    \'·.    `'´,.·:´';   ;::\'         //
//        ,' ,'::::\·²*'´¨¯':,'\:;     ',   _,.-·'´:\:\‘    '\::\¯::::::::';   ;::'; ‘        //
//        \`¨\:::/          \::\'      \¨:::::::::::\';      `·:\:::;:·´';.·´\::;'            //
//         '\::\;'            '\;'  '     '\;::_;:-·'´‘            ¯      \::::\;'‚           //
//           `¨'                          '¨                              '\:·´'              //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract ALG is ERC1155Creator {
    constructor() ERC1155Creator("Alice in editions", "ALG") {}
}