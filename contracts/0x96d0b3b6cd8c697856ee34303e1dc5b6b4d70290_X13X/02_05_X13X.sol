// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TRECE MUERTEZ
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                      //
//                                                                                                                  .......'',,,;;,,,''......                                                                                           //
//                                                                                                       ..';clodxkO00KKXNNNWWWWWWWWWWNNNXXK00Okxdolc:;'..                                                                              //
//                                                                                                    .lO0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKOo'                                                                           //
//                                                                                                     oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd'                                                                         //
//                                                                                                   .lKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0kkkkkkkkkkkkkkkkd;                                                                        //
//                                                                                                 ,dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd:.                                                                                       //
//                                                                                              .:kNMMMMMMMMMMMMNx:;xNWMMMMMMMMMMMMMMMMMMMMMMMMWXkl'.    .',:cloddxxxdolc;.                                                             //
//                                                                                            .l0WMMMMMMMMMMMMWO,   cKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0doxOKNWMMMMMMMMMMMMMWXOd;.                                                         //
//                                                                                          ,dXMMMMMMMMMMMMMMMx..c. cXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNO;                                                        //
//                                                                                       .:kNMMMMMMMMMMMMMMMMWo:KK, cXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                                                       //
//                                                                                     .oKWMMMMMMMMMMMMMMMMMMWXXMK, cXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWMMMMMMMMMMMMMMMMMMMX:                                                      //
//                                                                                  .;xXMMMMMMMMMMMMMMMMMMMMMMMMMK, cXNMMMMWK00KKXXNWMMMMMMMMMMMMN0koc:;,,,,;;:cldx0XWMMMMMMMMMMMx.                                                     //
//                                                                                  .:cccccccccccco0WMMMMMMMMMMMMK, cXNMWKd:'.....;xNMMMMMMMMWKxc'.                 .,cxKWMMMMMMMK;                                                     //
//                                                                                                 ;XMMMMMMMMMMMMK, cKNNOdokx;  .c0WMMMMMMMNx:.   .,coxkkkkkxxdoc:,.    .;dXMMMMMWl                                                     //
//                                                          .:ldxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx0WMMMMMMMMMMMMK, :Ox;.'ll.  .c0WMMMMMMXd'   .;d0NMMMMMMMMMMMMMMWXOdc'.  .lKMMMMd                                                     //
//                                                        ;kXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOdooloo. .. .cl,...   :NMMMMNk'   .cOWMMMMMMMMMMMMMMMMMMMMMMNOo'  .dNMMx.                                                    //
//                                                      .dNWNK0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0XMMMWXOdc;::;,.   .;O0ddOKKk' :NMMMXl.  .c0WMMMMMMMMMMMMMMMMMMMMMMMMMMMNx,  :KMk.                                                    //
//                                                     .xKx:'.  ...................................cXMMWXKXKkl;';ll:;;;o0O;.c0K; :NMMXc   ,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo. ;Kk.                                                    //
//                                                     co'  'coxkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOk0WMMMMMMMMN0l. 'odl;..;c;..,. :NMWd. .lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc  co.                                                    //
//                                                    .. .:ONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd' ':lo:..;lc.  :NMWc  ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK, ..                                                     //
//                                                      .xWWX0OkkkkOkkOOOOOOOOOOOOOOOOOOOOOOOOkkkkkOOkkkkkOkkOkOXMXx,. .coc..;c. :NMWc  ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:                                                       //
//                                                     .kKd;..  ................................................oWMMNKk;..:ol.   :NMWl  ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk.                                                      //
//                                                     co. .,lxkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOXMMMMMMWO:..;dl. :NMWl  ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkc.                                                       //
//                                                    .. .cONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c..'. :NMWl  ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXxc'.;c.                                                      //
//                                                      .kWWKOkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxKWMMMMMMMMMWKo. .xWMWc  ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c.  'OWW0;                                                     //
//                                                     .k0o,.  .................................................oNMMMMMMMMMMMMXOXMMMWc  ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWl    '0MMNo                                                     //
//                                                     cl. .:ok00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKNMMMMMMMMMMMMMMMMMMMWc  ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.   lNMWo.                                                     //
//                                                     . .lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWc  ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOooONMMk.                                                      //
//                                                      'OWN0xdddddoddddddddddddddddddddddddddddddddddddddddddddoddodddddddddxXMMMMMWc  .OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo                                                       //
//                                                     'kOc'.                    ............................................'kMMMMMWc   .oXMMMMMMMMW0kNMMWXKXNNWMMMMMMMMMMMMMMM0:.                                                     //
//                                                     ::.                   .:dO0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXWMMMMMWc     .dXMMMMMMX:'0MMWO;'.',ckNMMMMMMMMMMMMMNc                                                     //
//                                                     .                   .oXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWc       'dKWMMM0'cNMMMWXxol:..dWMMMMMMMMMMMMWo                                                     //
//                                                                        ,0WXOxdoooooooooooooooooooooooooooooooooooooooooooooOWMMMMWc         .,:lc.,0MMMMMMMMMWo .ckNMNKNMWNNMMMx.                                                    //
//                                                                       ,OOc.   ....'''''''''''''''''''''''''''''''''''''''''oNMMMMX:              ,0MMMMMMMMMWx.    cXx'xNd'oNMWl                                                     //
//                                                                      .c:   'okKXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNWMMMMM0'             ;KMMMMMMMMMNo.     .:'.oc. ;XMk.                                                     //
//                                                                       .  'xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo            .lXMMMMMMMMMXc          ..   lNk'                                                      //
//                                                                         ;KWKxolccccccccccccccccccccccccccccccccccccccccccccccccc;.            lWMMMMMMMMMMX;   ...    '.  :xl.                                                       //
//                                                                        ,Ox;.                .................................'.               'kWMMMMMMMMMM0dddl;. .cxc  .,.                                                         //
//                                                                       .:,                ,okKXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXk;                .,o0WMMMMMMMMMNx;;lkXK:                                                               //
//                                                                                        ,kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl.                    .;xXWMMMMMMMWNWMNd.                                                                //
//                                                                                       lXN0xolllllllcccllllclllccclllllclcl:.                         .cONMMMMMMMMNl                                                                  //
//                                                                                      cOo,.                           .                                  ,dKWMMMMMX;                                                                  //
//                                                                                     .c'  .:okO0000000000000000000OOxl;.                                   .ckXWMNd.                                                                  //
//                                                                                        .dXWMMMMMMMMMMMMMMMMWNKOxl;,.                                         .,;'                                                                    //
//                                                                                       ;KWN0kxddddddddddool:;'.                                                                                                                       //
//                                                                                      ;0Oc'.                                                                                                                                          //
//                                                                                     .l:                                                                                                                                              //
//                                                                                     ..                                                                                                                                               //
//                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract X13X is ERC721Creator {
    constructor() ERC721Creator("TRECE MUERTEZ", "X13X") {}
}