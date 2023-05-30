// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Driven By Boredom Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                  ,o;:l,l:                                'l;:c,,c:                                'o;:l,l:.                    //
//                  cKoxOl0d.                               cKoxOll0x.                               :Kox0lOx.                    //
//                  cKoxOl0d.                               cKoxOll0x.                               :Kox0lOx.                    //
//                  cKoxOl0d.                               cKoxOll0x.                               :Kox0lOx.                    //
//                  cKoxOl0d.                               cKoxOll0x.                               :Kox0lOx.                    //
//                  cKoxOl0d.                               cKoxOll0x.                               :Kox0lOx.                    //
//           ...... cKoxOl0k'........                 ..... cKoxOll0k'........                 ..... :KoxOlOk,.........           //
//        .;oxxxxxxxOKoxXOXKOKKOOK0kxxo;.         .;oxxxxxxxOKoxKO0XKO00OOK0kxxo;.         .;oxxxxxxxOKdxXOXKO0KOOK0kxxo;.        //
//      .;kkl,.....,xX0KKkKK0Ol,;o0k:,lOk;       ;kOl,.....;xX0KKkkKK0Ol;;o0k:;lOk;       ;kOl,.....,xX0KKkKK0Ol,;o0k:,lOk;.      //
//      cKo.        :XNNOl0Nd.    'kO, .d0c     c0d.        :XNNOllONd.    ,kO, .d0c     cKd.        :XNNOlONd.    'k0, .dKc      //
//     '0k.         cKO0Ol0O.      ,Kd. .OO.   'Ok.         :KO0Oll0O.      ,0x. .kO.   .OO.         :KO00lOO.      ,0x. .kO'     //
//     ,Kx.         cKxOOl0x.      '0k. .x0'   ,0x.         :KxOOllOk.      'Ok. .x0,   ,0x.         :KxkOlOk.      .Ok. .x0,     //
//     .x0,         'kXXo.d0;     .lKl  ;0x.   .x0;         'kXXd''dK;      lKl  ;0x.   .x0;         .kXXd.dK:      cKl  ;0x.     //
//      'xOc.       'xNXl..x0l.  'd0l..l0x.     'xOc.       .xNXl. .x0l.  'o0o..c0x'     .x0l.       .xNXo..d0l.  'o0o..c0x'      //
//       .:xkdlc:cldkxclkkdd0N0xkKXkodkx:.       .:xkdl::cldkxclkkxoo0X0xxKXkodkx:.       .:xkdlc:cldkxcckkdoONKxkKXOodkx:.       //
//         .':loolc;.   .':loolcclolc;..           .':loool:'.  .';:loollllool:'.           ..;coolc;.   .':llolccloll:'.         //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                  ,l;:c,l:                                'l;:c,,c:                                'l;:l,l:.                    //
//                  cKoxOl0d.                               cKoxOll0x.                               :Kox0lOx.                    //
//                  cKoxOl0d.                               cKoxOll0x.                               :Kox0lOx.                    //
//                  cKoxOl0d.                               cKoxOll0x.                               :Kox0lOx.                    //
//                  cKoxOl0d.                               cKoxOll0x.                               :Kox0lOx.                    //
//                  cKoxOl0d.                               cKoxOll0x.                               :Kox0lOx.                    //
//            ..... cKoxOl0k'........                 ..... cKoxOll0k'........                 ..... :Kox0lOk,........            //
//        .;oxxxxxxxOKoxXOXKO0KOOK0kxxo;.         .;oxxxxxxxOKoxXO0XKO00OOK0kxxo;.         .;oxxxxxxxOKoxXOXKO0KOOK0kxxo;.        //
//      .;kkl,.....,xX0KKkKK0Ol,;o0k:;lOk;       ;kOl,.....;xX0KKkkKK0Ol;;d0k:;lOk;       ;kOl,.....,xX0KKkKK0Ol;;o0k:,lOk;.      //
//      cKd.        :XNNOl0Nd.    ,kO, .d0:     c0d.        :XNNOllONd.    ,kO, .d0c     c0d.        :XNNOlONd.    'k0, .dKc      //
//     '0k.         cKO0Ol0O.      ,0d. .OO.   'Ok.         :KO0Oll0O.      ,0x. .OO.   .Ok.         :KO00lOO.      ,0x. .kO'     //
//     ,Kx.         cKxOOl0x.      '0k. .x0'   ,0x.         :KxkOllOx.      'Ok. .x0,   ,0x.         :KxkOlOk.      .Ok. .x0,     //
//     .x0,         'kXKo.d0;     .lKl  ;0x.   .x0,         'kXXd''d0;      cKl  ;0x.   .x0;         .kXXd.dK:      cKl  ;0x.     //
//      'xOc.       .xNXl..xOl.  'd0l..l0x.     'xOc.       .xNXl. .xOl.  .o0o..c0x'     .x0l.       .xNXo..d0l.  'o0o..c0x'      //
//       .:xkdlc:cldkxclkkdo0N0xkKXkodkx:.       .:xkdl:::ldkxclkkxoo0X0xxKXkodkx:.       .:xkdlc:cldkxclkkdoONKxxKXOodkx:.       //
//         .':loooc;.   .':loolccloll:..           .':loool:'.  .,;:loollloool:'.           .':loool;..  .':loolccloll:'.         //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                  ,l;:c,c;                                'l,:c,,c;                                'l;:c,c;                     //
//                  cKokOl0d.                               cKokOlo0d.                               cKoxOl0x.                    //
//                  cKokOl0d.                               cKoxOlo0d.                               cKoxOl0x.                    //
//                  cKokOl0d.                               cKoxOlo0d.                               cKoxOl0x.                    //
//                  cKokOl0d.                               cKoxOlo0d.                               cKoxOl0x.                    //
//                  cKokOl0d.                               cKoxOlo0d.                               cKoxOl0x.                    //
//            ..... cKokOl0x'........                 ..... cKokOlo0x.........                 ..... cKoxOl0k'........            //
//        .;oxxxxxxdOKoxKOX0O00OO00xxdl,.         .,lxxxxxxdOKoxKO0XKk00kO0Oxxdl,.         .,lxxxxxxdOKoxKOXKO00OO00kxxl,.        //
//      .;kOl,.....;kX0KKkKK0Ol;:d0k:;oOx,       ;kOo;.....;kX0KKOOKK0Oo;:d0k:;oOx,       ;kOo;.....;xX0KKOKK0Oo;:d0k:;oOx,       //
//      c0d.        cXNNOl0Nd.    ,OO' .x0:     c0d.        cXNNOlo0Nx.    ,OO' .x0:     c0d.        :XNNOlONx.    ,OO, .x0:      //
//     '0k.         cKOKOl0O.      ;Kd. 'Ok.   'Ok.         cKOKOlo0O.      ;Kd. .OO.   'Ok.         cKOKOl0O.      ;Kd. .OO.     //
//     ;Kd.         cKdOOl0x.      '0x. .k0'   ,Kd.         cKxOOlo0x.      '0k. .x0'   ,0x.         :KxOOl0x.      'Ok. .x0,     //
//     .k0,         'OXKo'x0,     .lKl  ;0d.   .k0,         'OKKd',x0,      lKl  ;0x.   .x0,         'OXKd'd0;      cKl  ;0x.     //
//      'kO:.       .xNXc.'xOc.  .o0o..c0x.     'kO:.       .xNXl. 'xOc.  .o0o..cOx'     'kOc.       .xNXl..xOc.  .o0o..cOx'      //
//       .ckkoc:::ldkxcokkoo0X0dxKXkodkx:.       .ckkoc:;:cdkxlokkdoo0XOdxKXkodkkc.       .ckkdc:::ldkxclkkoo0X0dxKXkodkkc.       //
//         .':loool:'.  .,clooolloool:'.           .,cloool:'.  .,:coooolloool:'.           .':loool:'.  .,clooolloool:'.         //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DBBE is ERC1155Creator {
    constructor() ERC1155Creator("Driven By Boredom Editions", "DBBE") {}
}