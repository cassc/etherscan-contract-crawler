// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Squab HQ: Chimera Corp
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                         ............                                                                         //
//                                                                 .':coxkO0KKXXXXXXKK0Okxol:,..                                                                //
//                                                            .;lxOXNWMMMMMMMMWWWMMWMMMMMMMMWWX0xo:.                                                            //
//                                                        .,lkXWMMMMWXKOxolcc::;;;;;::cloxk0XWMMMMWXOo;.                                                        //
//                                                     .,o0NMMMWXOdc;..                    ..,coOXWMMMWKx:.                                                     //
//                                                   .cONMMMW0d:.                                .;oONMMMW0o'                                                   //
//                                                 .c0WMMWXd;.                                      .,o0WMMWXd.                                                 //
//                                                ;OWMMWKl.               ......''......               .:OWMMWKc.                                               //
//                                              .lXMMMXo.         .';codkO0KKXXNNNNNXXK0Okxol:,.         .c0WMMNx.                                              //
//                                             .oNMMM0;      .,cdOKNWMMMMMMMWWWWWWWWWWMMMMMMMWNX0xl;.      'kWMMWk.                                             //
//                                             :XMMM0;   .,lkKNMMMMWNX0kdoc::;,,,,,,;;:cloxO0XWMMMMWXOo;.   .kWMMWd.                                            //
//                                            .kMMMNl .,o0NMMMMNKko:'..                     ..,cdOXWMMMWKx:. ;KMMMK,                                            //
//                                            '0MMMXolONMMMWXkl,.                                 .;oONWMMWKdl0MMMN:                                            //
//                                            .kMMMWWWMMWXx:.                                         'lONMMMWWMMMK;                                            //
//                                             cNMMMMMW0l.                                              .,dXWMMMMWd.                                            //
//                                            .oNMMMW0c.                                                   .oKWMMWO,                                            //
//                                           ,kWMMMKl.                                                       'dNMMMKc.                                          //
//                                          :KMMMWk'                                                           :0WMMNd.                                         //
//                                         cXMMMNo.                           .:cccc:,..                        'kWMMWx.                                        //
//                                        :KMMMNl.                            ,0MMMMMWNKko;.                     .xWMMWd.                                       //
//                                       '0MMMNo.                              dWMMMMMMMMMWKd;                    .kWMMNc                                       //
//                                      .dWMMMk.                               oWMMMMMMMMMMMMNk,                   ,KMMM0'                                      //
//                                      ,KMMMX:                               .OMMMMMMMMMMMMMMMKc                   oWMMWl                                      //
//                                      lWMMMO.                              .dNMMMMMMMMMMMMMMMMX:                  ,KMMMk.                                     //
//                                     .xMMMWd.                            .:OWMMMMMMMMMMMMMMMMMMO.                 .OMMMK,                                     //
//                                     .kMMMWo                          .,lONMMMMMMMMMMMMMMMMMMMMK;                 .kMMMX;                                     //
//                                     .kMMMWo                  ,oollodkKNMMMMMMMMMMMMMMMMMMMMMMMK,                 .OMMMX:                                     //
//                                     .dWMMMx.                 ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.                 ,KMMMK;                                     //
//                                      :XMMM0,                  lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,                  lNMMMk.                                     //
//                                      .OMMMWo                  .cKMMMMMMMMMMMMMMMMMMMMMMMMMMWk'                  'OMMMNl                                      //
//                                       cXMMMK;                   'dXMMMMMMMMMMMMMMMMMMMMMMW0c.                  .dWMMMk.                                      //
//                                       .dWMMM0,                    'lOXWMMMMMMMMMMMMMMMWKx;.                    cXMMMK;                                       //
//                                        .xWMMWO,                      .;lxO0KXXXXXK0kdc,.                      lXMMMX:                                        //
//                                         .xWMMMK:                          ........                          .oNMMMK:                                         //
//                                          .oNMMMXd.                                                         ,OWMMW0;                                          //
//                                            :0WMMW0c.                                                     'dXMMMNd.                                           //
//                                             lNMMMMW0c.                                                 'dXWMMMMk.                                            //
//                                            .kMMMMMMMWKo,.                                           .:kNMMMMMMMK,                                            //
//                                            '0MMMN0KWMMMNOo,.                                     .:xKWMMMX0XMMMX:                                            //
//                                            .OMMMNl.:xXWMMMNKxc,.                            ..:oOXWMMMN0o,:KMMMK;                                            //
//                                             cNMMM0'  .:d0NMMMMWXOxl:,'..            ...';cok0NWMMMWXOo,. .xWMMWx.                                            //
//                                             .dWMMWO,    .,cx0XWMMMMMWNXK0OkkxxxxxkkO0KXNWMMMMWNKko:.    .dNMMWO'                                             //
//                                              .oNMMMKc.      ..;cok0KNWWMMMMMMMMMMMMMMWWNXKOxl:'.       ;OWMMWk'                                              //
//                                               .cKWMMWO:.           ..,;:clloooooolllc:,'..           ,xNMMMXo.                                               //
//                                                 .oXWMMW0l'                                        .ckNMMMNk,                                                 //
//                                                   'oKWMMWNOl,.                                .'cxKWMMWXx,                                                   //
//                                                     .:kXWMMMNKxl;'.                      ..,cd0NWMMMNOl'                                                     //
//                                                        .:d0NWMMMWNKkdoc:;,,''''''',;:cldk0XWMMMMWKkl'                                                        //
//                                                           .'cdOKNWMMMMMMWWWNNNNNNNWWMMMMMMMWX0xl;.                                                           //
//                                                                .':ldxO0KXNNNWWWWWNNXKKOkdl:,..                                                               //
//                                                                       ....'',,,,,'....                                                                       //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SQB is ERC721Creator {
    constructor() ERC721Creator("The Squab HQ: Chimera Corp", "SQB") {}
}