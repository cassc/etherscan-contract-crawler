// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Squabble Heads
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                 ..',;:cclllllcc:;,'..                                                                                 //
//                                                                           .,coxOKXNWMMMMMMMMMMMMMWWNKOkdc;..                                                                          //
//                                                                      .,cdOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0xl;.                                                                      //
//                                                                   .:d0NMMMMMMMMMWXK0OkxdddddddxkkOKXNWMMMMMMMMWXkl'                                                                   //
//                                                                .:xXWMMMMMMWXOdl:,..               ..';cokKNMMMMMMMNOl'                                                                //
//                                                              ,dKWMMMMMWKkl,.                             .'cd0NMMMMMMNk:.                                                             //
//                                                            ,xNMMMMMW0d;.                                     .,lONMMMMMW0c.                                                           //
//                                                          'xNMMMMMXx;.                                            'o0WMMMMW0:                                                          //
//                                                        .lXMMMMMKo'                                                 .cOWMMMMNx'                                                        //
//                                                       'kWMMMMXd.                  ...'',;;;;;;,''...                 .c0WMMMMK:                                                       //
//                                                      ,0MMMMWO,            ..,cldkOKXNNWWWMMMMWWWNXK0Oxol:'.            .dNMMMMXc                                                      //
//                                                     ,0MMMMWd.         .:ok0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKOdc,.         cXMMMMNc                                                     //
//                                                    .kMMMMWd.      .:dONMMMMMMMMMMMWNXK0OOOOOOO00KXNWMMMMMMMMMMWKkl,.      :XMMMMX;                                                    //
//                                                    lWMMMMk.    'ckXWMMMMMMMWXOxoc;'...         ....,;cox0XWMMMMMMMW0d;.    lWMMMMk.                                                   //
//                                                   .OMMMMX:  .ckNMMMMMMWXOdc,.                            .,cd0NMMMMMMW0d,  .OMMMMX;                                                   //
//                                                   ,KMMMMO''dKWMMMMMWKd:.                                     .'cxKWMMMMMNk:.dWMMMWl                                                   //
//                                                   ,KMMMMKOXMMMMMWKd;.                                            .:xXWMMMMW0KWMMMWl                                                   //
//                                                   .kMMMMMMMMMMNk:.                                                  .l0WMMMMMMMMMX;                                                   //
//                                                    :XMMMMMMMNx;                                                       .:OWMMMMMMWd.                                                   //
//                                                    :KMMMMMNk,                                                            :OWMMMMWd.                                                   //
//                                                   cXMMMMW0:.                                                              .lXMMMMWk'                                                  //
//                                                 .dNMMMMNx.                                                                  'kWMMMM0;                                                 //
//                                                .xWMMMMXl.                                                                    .dNMMMMK;                                                //
//                                               .xWMMMMK:                                 ..''...                                lXMMMMK;                                               //
//                                              .oWMMMMK:                                 ,0NNNNXK0kdc,.                           cXMMMM0'                                              //
//                                              cXMMMMXc                                  .dWMMMMMMMMMWKd;.                         lNMMMMk.                                             //
//                                             '0MMMMWo                                    ;XMMMMMMMMMMMMW0l.                       .xWMMMNl                                             //
//                                             oWMMMMO.                                    ,KMMMMMMMMMMMMMMW0:                       '0MMMM0'                                            //
//                                            '0MMMMNc                                     cNMMMMMMMMMMMMMMMMNd.                      lWMMMWl                                            //
//                                            cNMMMMO.                                    .kMMMMMMMMMMMMMMMMMMWx.                     '0MMMMk.                                           //
//                                           .xMMMMMd                                    .dWMMMMMMMMMMMMMMMMMMMWo                     .xMMMMK,                                           //
//                                           .OMMMMNc                                   'kWMMMMMMMMMMMMMMMMMMMMM0'                     lWMMMN:                                           //
//                                           '0MMMMX;                                 'oXMMMMMMMMMMMMMMMMMMMMMMMNc                     cNMMMWl                                           //
//                                           ,KMMMMX;                             .,lkNMMMMMMMMMMMMMMMMMMMMMMMMMWo                     cWMMMWo                                           //
//                                           '0MMMMX;                     ckxdddxOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWl                     oMMMMMd                                           //
//                                           .kMMMMWc                     lWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,                    .xMMMMWl                                           //
//                                            dMMMMMd.                    .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo                     '0MMMMX:                                           //
//                                            :NMMMM0'                     ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.                     :NMMMMO.                                           //
//                                            .OMMMMWl                      ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx.                     .xMMMMWo                                            //
//                                             lNMMMM0,                      .dXMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:.                      cNMMMM0'                                            //
//                                             .kMMMMWx.                       'dXMMMMMMMMMMMMMMMMMMMMMMMW0l.                       '0MMMMNl                                             //
//                                              ;KMMMMNo                         .ckXWMMMMMMMMMMMMMMMMN0d;.                        .kWMMMWx.                                             //
//                                               cNMMMMNl                           .;ldk0KXXXXXXKOkoc,.                          .xWMMMMO'                                              //
//                                                lNMMMMNl.                               ........                               .xWMMMM0,                                               //
//                                                .lNMMMMNd.                                                                    'OWMMMM0,                                                //
//                                                  cXMMMMWO,                                                                 .cKMMMMWO'                                                 //
//                                                   ,0WMMMMXo.                                                              'kWMMMMNd.                                                  //
//                                                    :NMMMMMWKc.                                                          .dXMMMMMMk.                                                   //
//                                                   .xMMMMMMMMW0c.                                                      'dXMMMMMMMM0'                                                   //
//                                                   ,0MMMMMMMMMMWKo,                                                 .;xNMMMMMMMMMMWc                                                   //
//                                                   ,KMMMMKdOWMMMMMNOl'                                           .,o0WMMMMMNk0MMMMWl                                                   //
//                                                   '0MMMMK,.:kNMMMMMMNOo;.                                    ':d0WMMMMMWKd'.kMMMMNc                                                   //
//                                                   .dWMMMWd.  'lONMMMMMMWXko:,.                         ..;cd0NMMMMMMWXk:.  :XMMMM0'                                                   //
//                                                    ,KMMMMXc    .,lOXWMMMMMMMWXOxol:;,'..........',;cldk0XWMMMMMMMWKxc.    '0MMMMNl                                                    //
//                                                     cXMMMMX:       .:dOXWMMMMMMMMMMMWNNXXKKKKXXNNWMMMMMMMMMMMWKkl;.      'OWMMMWd.                                                    //
//                                                      cXMMMMNo.         .;ldOKNWMMMMMMMMMMMMMMMMMMMMMMMMWX0koc,.         ;KMMMMWx.                                                     //
//                                                       :KMMMMWO;             .';cloxkO0KKKKKXKKK00Okdol:,..            .xNMMMMNd.                                                      //
//                                                        'OWMMMMNx,                    ...........                    .oXMMMMMK:                                                        //
//                                                         .lKMMMMMNk:.                                              ,dXMMMMMNx'                                                         //
//                                                           .oXMMMMMWKd;.                                        'lONMMMMMNk,                                                           //
//                                                             .l0WMMMMMWKxc'.                                .;oONMMMMMMXx,                                                             //
//                                                               .:xXWMMMMMMN0xl:'.                     ..;cdOXWMMMMMMNOl.                                                               //
//                                                                  .:xKWMMMMMMMWNK0kdolc:::::::::clodxOKNWMMMMMMMWXkl'                                                                  //
//                                                                     .,lkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOo:.                                                                     //
//                                                                         .,:ox0XNMMMMMMMMMMMMMMMMMMMMMWX0kdc;.                                                                         //
//                                                                               .';cloddxkkOOOOkkxdolc;,..                                                                              //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SQBHDS is ERC1155Creator {
    constructor() ERC1155Creator("Squabble Heads", "SQBHDS") {}
}