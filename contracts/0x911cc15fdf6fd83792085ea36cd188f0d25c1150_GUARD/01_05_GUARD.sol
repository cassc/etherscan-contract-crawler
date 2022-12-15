// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Guardians of the Ethereal Light
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//              .....          ...       ..            ...           .........          .......               //
//          .:oxxxdl:;'..    .:oxx;    .oOOk;        .;odo;.        ;kOkkkkkkxdl,.    'oxxdxxxxxxo;.          //
//        .o0K0000kxddodd;.  'kO0Xl    'OXKXo       .cOdloo;        oN0kK000OOOkkd,   ;0OxO000KKKKKOc.        //
//       ,OXO0Kxc,'';oO0KO;  '00OXl    'OKOXo       cKOxkxxk;       oNO0Nd;,,c0Kk0k'  ;KOONOc::lkK00Xx.       //
//      .xNO0Xl.   ...;cc:'  ,00OXl    'OKOXo.     :K0OXNKkOO;      lNOOK;   .dKkO0;  ;X0ONo.   .lX0OXl.      //
//      '0KOXO.   :OOxxxkOx' ,00OXl    'OKOXo.    :00OKd:d0O00;     lXkxxl::cdOxdOx.  ;X0ONo.    'OKOXk.      //
//      'xOxK0,   lKK000kKK; ,00OXl    'OKOXo.   ;00OXk'.,kXO0O,    lXxldddooooccc.   :X0ONo.    ,0KOXx.      //
//      .:kkkKk;. .';dXKOXk. 'O0kXd.   :K0OXl   ,OOdOK0kxk0XOd0O'   lKkdxoc:;;ccl,    :X0ONx. ..:OKOKK;       //
//       .cO0OOOkxdxkO00KO,  .lKOO0kddx00OKO'  'dOddkkO00O00KkxKk'  lXOkO; .',;loo;.  :X0kXKkxkO000KO;        //
//         'lk000KK0K0Okc.    .:xO0KKKKK0Od'  .oxdxo:'',,,,,l0XNWx. lNNX0;   .cxkO0l. ;KN00K0000OOkc.         //
//           .';clllc;..        .':clllc,.    .,,,'.         .:cc;. .;c:,.    .;::c,. .,cccccc:;,.            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GUARD is ERC721Creator {
    constructor() ERC721Creator("Guardians of the Ethereal Light", "GUARD") {}
}