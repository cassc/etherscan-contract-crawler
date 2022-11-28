// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Static City
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//            ..',,'..      ..''''''..''''''..          ..''..           ..''''''..''''''..  .'''.         ..''''..               //
//         .;dOKXXXXX0kd;.  ,ONXKKK0OO0KXXXX0;         .o00Okl.          ,ONXKKK0OO0KXXXX0; .kXX0:     .'cxOO0KK0Okdc'.           //
//        .dNWNX0kxkOXWWx.  .dkkxxOKO0X0xxxkd'        .l00dox0o.         .dkkxxOKO0X0xxxkd' 'OXXXc    ,xXNNXK0Oxx0XNNXo.          //
//        :KXNWk'   .':c.         ;O0KXc             .cOKKOkO00l.              ;00KXc       'kKKKc  .c0NWXkc'.....;oOd,           //
//        ;KXKXKd;..              ;0KKKc             :0KKKlcO0KKc.             ;0KKX:       'OXKKc  ;KNXKo.         .             //
//        .:OXNWWNKOxo:'          ;0K00:            ,OXXKl..cKKXK:.            ;0K00:       'kXKKc .oNXXx.                        //
//          .,cdk0XNNNNXx'        ;0KKK:           'kXKKd'..'dKKX0d;           ;0KKK:       'OXKKc .oNNXx.                        //
//               .':dKXNNx.       ;0KKX:          'xKOOOOOOkkO0OOKNO,          ;0KKX:       'kKKKc  :KNXKc.                       //
//        .:do:..   ,kKXWO'       ;0XXK:         .dKOxO0OOOkkO0OkOXKd.         ;0XXK:       'kKO0:  .oKKK0d,.    .'ldc.           //
//       .cXMWWXOxxk0NXXKc.       ;0NNX:        .dXNXOc'.......:xKXXKd.        ;KNNX:       'kKKXc   .:OXNNKOxdoxOXWWXl.          //
//        .;okKXNWWWNK0d,         ;KWNK:       .lXWNO,          ;OXNNXo.       ;KWNK:       .kXNXc     .:dOKXNNNXXKOo:.           //
//           ..';;;;,'.           .,:;,.        ';;;.            .,;::,.       .;:;,.        ';;,.        ..,;;;,'..              //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                 .':lddxxxol:.    'dkko. .lkkxxxxdooddxxxkx,  ;ddo;.       'lxkc.                               //
//                               .ckXNNXXXKKXNXKx;  :KNNO, .kNXKKKXK00KXKKXXKc  'kNWNk'    .lKWWK:                                //
//                              ,kNWN0xc:;,;cx0X0:. :00K0,  .''''cdO00Xx,'''..   .oNWNO,  .oXNN0;                                 //
//                             ,0XXXx'        .,.   :KKKO,       .ckKKNo          .cKWNO:;xXXXO,                                  //
//                            .oNXXx.               ;0XXO,       'lkK0Kl            :0NKOOXNKd'                                   //
//                            .xNXXo.               ;0XXO,       'lkK0Kl             ;O0xdOKd.                                    //
//                            .oXNXk'               :0KXO,       'lOKKXo              :000Kx.                                     //
//                             ,kXKKx,       .,;.   :000k'       'lOXKXl              'kXXXl                                      //
//                              ,xKXXKxl:;:cokXW0:  :00KO,       'lONNXl              'OWNXc                                      //
//                               .:kKXNWNNNNWWX0d,  :0XNK;       'lOWNNo              '0WWNl                                      //
//                                  .;looddol:,.    .lddc.       .,cddo,              .cdxd,                                      //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract STCTY is ERC721Creator {
    constructor() ERC721Creator("Static City", "STCTY") {}
}