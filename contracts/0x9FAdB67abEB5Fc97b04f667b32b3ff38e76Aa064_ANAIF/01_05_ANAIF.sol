// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AI Future
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                        //
//                                                                                                                        //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    //                                                                                                            //    //
//    //                                                                                                            //    //
//    //                                                                                                            //    //
//    //                                                                                                            //    //
//    //                                                                               .;:;'    .;clc;.             //    //
//    //                                                                             ,xXWMMNk,.lXWMMMWKo.           //    //
//    //                                                                            ;XMMMMMMMKONMMMMMMMWx.          //    //
//    //                                                                            dMMMMMMMMMMMMMMMMMMWx.          //    //
//    //                                                                            ,0WMMMMMMNKKNMMMMMWO;           //    //
//    //                                                                            .:kXMMMKl'..,dNMMMWNK0o.        //    //
//    //                                                                         .:kKNNWMMNc     .xMMMMMMMM0'       //    //
//    //                                                                         oWMMMMMMMWd.    '0MMMMMMMMWc       //    //
//    //          .clodddxkOOxdddooooooooooodoooooloooooolllllolccclodkkkkkkkxo;.dMMMMMMMMMW0dllxXMMMMMMMMMK;       //    //
//    //         cKWMWWWWMMMMMMWNXXNWMWWMMMMMMMMMMMWNXNWXOk0XKK00K0KXNWMMMWWMMMNc'OWMMMMMWXXMMMMMMMMK0XNNXk,        //    //
//    //        .OMMMWWNNWMMMWMMWNX0x00k0XNWMMMMMMWNOlxkooclxOOKNXKKXNNWMMMMMMMMKo;lk0K0kc;OMMMMMMMMO,.'..          //    //
//    //        ;KWWNWWKKWMWWWMMMWMWKKX00OxXWMMMMW0O0KOxdxOkxXN0OOkOKWWWMMMMWNXWMMXxlooll,'OMMMMMMMMK,              //    //
//    //        cXWWWWXKXNWWNWWWWWWWNNKxddkKNWNNW0dd0WOoxOXK0NWNXNWN0XWWMMMMNXNMMMMMMMMMM0,cNMMMMMW0:               //    //
//    //        lWNXNNXNWWWNNWWWWXkddxdoocclk0xkX0kxkOxodxOXK0XNNNNX0KNWWMMWWWWMMMMMMMMMMWOc:ldxdl;.                //    //
//    //        cNWNNNMMMWWWWWWWWO'          .  .'..      ......'''...',,;;,;oKMMMMMMMMMMMMWKkx;                    //    //
//    //        ,KWWMMMMMWWMMMMMWo.                                          .xMMMMMMMMMMMMMMMMk.                   //    //
//    //        :NMMMMMMWNWMMMMMK,                                           .xMMMMMMMMMMMMMMMM0'                   //    //
//    //        oMMMMMMMWWMMMNNMK,                                            oMMMMMMMMMMMMMMMMK,                   //    //
//    //        dMMMMMMMMMMMMX0XX;                                            cWMMMMMMMMMMMMMMMK,                   //    //
//    //       .xMMMMMMMMMMMMWKKO'                                            ;XMMMMMMMMMMMMMMMK,                   //    //
//    //       .kMMMMMMMMMMMMMWWK,                                            ,KMMMMMWWMMMMMMMMK,                   //    //
//    //        oMMMMMMMMMMMMW0KX:                                            :XMMWNNNNMMMMMMMMk.                   //    //
//    //        lWMMMMMMMMMMMMNXNl                                            ,KMMNKNMMMMWMMMMNl                    //    //
//    //        lWMMMMMMMMMMMMMMMk.                                           ,KMMMMMMMMMNNMMMNc                    //    //
//    //        :XWWMMMMMMMMMWWWKl.                                           ,KMMMMMMMNKNWWMMWl                    //    //
//    //        'OKKMMMMMMMMMMWWNc                                            ,KMMMMMMMXOXMWWWWx.                   //    //
//    //        .k0KWMMMMMMMMMMWNKOddxllllldO0O0dccoxxl;;::;::;,....   .. .;l:xNMMMMMMMMMMMNXWNo.                   //    //
//    //        .lKWWMMMMMMMMMNNWMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMWNXXKxdOK0O0NMMMMMMWNNMMMMMMXKNNo.                   //    //
//    //         cXNNWMMMMMMMWXXMMMWMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMWdc0WMMMMMMMMMMWWWMMMMNOOXKKo                    //    //
//    //         oNkOWMMMMMMWWMMMMXOkxlccc:coooooddxk000KXKK00000OO0Odk000KWMMMMMMMMMMMMMWOldxkl.                   //    //
//    //         dWXNMMMMMMMMMMMMX:                     .....  .   ........,:o0WMMMMMMMMMMXxlkKx.                   //    //
//    //         oWMMMMMMMMMMMMMMk.                                           :NMMMMMMMMMMMWNK0x'                   //    //
//    //         cNWWMMMMMMMMMMMWd.                                           cNMMMMMMMMMWWWWXOko.                  //    //
//    //         :NWWWMMMMMMMMMMWo                                            lNMWWMMMMMKxxXMMN0l.                  //    //
//    //         :NWNWMMMMMMMMMMWd                                            ;KXKNWWMMN0OxOWMKl.                   //    //
//    //         ;XNXWMMMMMMMMMMWd.                                           'OXWNOONNKOk0KKX0l.                   //    //
//    //         :XWWWMMMMMMWMMMMx.                                           :XWMWXXW0kO0KX0KXk:.                  //    //
//    //        .dWWWMMMMMMMMMMMMx.                                           .kWWOd0KKKKk0WNNWW0'                  //    //
//    //         cXXXWWMMMMMMMMMMO.                                           .dkOkdxokWNKXNWMWWX;                  //    //
//    //         cNNWWWMMWWMMMMMMK,                                           :NXXXXX0KWMMWNNWMMX;                  //    //
//    //        .l0NNKXMMMNNWMMMMK,                                          .dWMMMMMMMMMMMMWWMMN:                  //    //
//    //        .clkOdOMMMNWMMMMMO.                                          ,KNWMMMMMMMMMMMMMMMWd.                 //    //
//    //        .,cxO0NMMMMMMMMMWo                                           .;',c:cl:::ldkOOkkko;.                 //    //
//    //          .',:lloollcccll.                                                                                  //    //
//    //                                                                                                            //    //
//    //                                                                                                            //    //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ANAIF is ERC721Creator {
    constructor() ERC721Creator("AI Future", "ANAIF") {}
}