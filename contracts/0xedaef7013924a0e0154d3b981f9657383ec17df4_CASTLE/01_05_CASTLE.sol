// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lil Castle ☆
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                               ';'.                                               //
//                                               dNKc                                               //
//                                          .,,,c0MM0c,;;.                                          //
//                                          'dKWWMMMMWWNx'                                          //
//                                            .dNMMMMM0;                                            //
//                                             cNWX0XWk.                                            //
//                                             lOl...cx,  .                                         //
//                                          .. .        ,kk'                                        //
//                                         .xKo'       ;KMWk.                                       //
//                                         ;XMMNx;,;;:lKMMMWo                                       //
//                                      .,c0MMMMMMMMMMMMMMMMK:.                                     //
//                                     :0WMMMMMMMMMMMMMMMMMMMNKkl'                                  //
//                                     .;kNMMMMMMMMMMMMMMMMMMMWKd,                                  //
//                         ..             ;OWMMMMMMMMMMMMMMMMKo.                                    //
//                         oXx'            .oNMMMMMMMMMMMMMWk'                                      //
//                        ,0MMKl.            lNMMMMMMMMMMMNo.            .                          //
//                       'OWMMMW0c.          .kMMMMMMMMMMNo.           .o0x,                        //
//                      :0WMMMMMMWKx:'.      ,0MMMMMMMMMMk.          'l0WMMNx,                      //
//                   .;kNMMMMMMMMMMMMNKOxdodkXMMMMMMMMMMM0;.....';cdONMMMMMMMNOc.                   //
//                 ,o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX00KXNWMMMMMMMMMMMMMMXx:.                //
//             .;oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXko:'.           //
//          .:xKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKk;         //
//         ;O0OkkkkOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xl;.         //
//         ...      ..:dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkc'.             //
//                      .oNMMMMMMMMMMMMMMMMWNKKNMMMMMMMMMWNMMMMMMMMMMMMMMMMMMMMMXd'                 //
//                        cXMMMMMMMMMMMMMXd:'.;0MMMMMMMMMO:dNMMNOdox0WMMMMMMMMNx'                   //
//                         oWMMMXkocco0WK;    oWMMMMMMMMMX;.l0d'    .:OWMMMMMK:                     //
//                         '0W0l.     .,.    cXMMMMMMMMMMMO. .        .dNMMWk'                      //
//                          :l.            .lXMMMMMMMMMMMMWx.          .oNWx.                       //
//                                 ....',,:kNMMMMMMMMMMMMMMWk,...        :l.                        //
//                       .';:cccccccccclxXWMMMMMMMMMMMMMMMMMMNOoccccllool:,.                        //
//                     ,lllc;,...    .;dXMMMMMMMMMMMMMMMMMMMMMNx;.  ..',;cldx:                      //
//                    .O0;.         .kWMMMMMMMMMMMMMMMMMMMMMMMMMNd.    .':oOXd.                     //
//                     ;OX0xoc;'... .,:d0NMMMMMMMMMMMMMMMMMMMMWKkocldkO0K0ko;.                      //
//                      .,cxOKXXXK0OOkxxkXMMMMMMMMMMMMMMMMMMMMNKK0Okdl:,..                          //
//                           ..,;clodxxkkOOOOXWMMMMMMMMMMWOc;;'...                                  //
//                                           .xNMMMMMMMMNo.                                         //
//                                             cXMMMMMMXc                                           //
//                                              ;KMMMMNc                                            //
//                                               ;KMMWd.                                            //
//                                                lXN0,                                             //
//                                                .:xl                                              //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract CASTLE is ERC721Creator {
    constructor() ERC721Creator(unicode"Lil Castle ☆", "CASTLE") {}
}