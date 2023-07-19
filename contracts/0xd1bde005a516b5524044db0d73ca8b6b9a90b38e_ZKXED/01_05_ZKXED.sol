// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ZKX_ED
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                            .                                               //
//                                     .'....                .lxl;.                                           //
//                                     'dKXX0koc,.            .xWWXOdc'.                                      //
//                                       lNMMMMMWd.            .xWMMMMNKc         ..'.                        //
//                                      :0WMMMWXO,              .dWMMMMMx.  ..,coxdc'                         //
//                                    'xKKkdl:,.   ..;:.         .OMMMMM0ook0XWXx;.                           //
//                                    ,;..   ..;cok0XWMk;.       .kMMMMMMMMMNOl.                              //
//                                     ..;cok0XWMMMWWWMNKc       .kMWWWWWWKd,                                 //
//                       .cooc:;'.';cdk0XWWWWWWWWWWWWXd;,.       .kWWWWNk:.   .':ll:'.                        //
//                        .:kNWWNXXWWWWWWWWWX0xoOWWWW0'          .kWWWWx',:lxOKNWWWWXOdc,.                    //
//                           ,dKWWWWWNXOxoc,..  cNWNWK,          .kWNWNXKNWWWWNWWWWWWWWWNKko:.                //
//                     .:,     .lkxo:,.         :XNNWXc.         .kWNNNNNNNWNXKkxOXNWNNNNNNWNXk'              //
//                    ,0NXkc.                 ..dXNNNNX0Oko.     .xNNNNX0kdl;'.   .;oKNNNNNNNKc               //
//                    .kNNNN0d;.  :c    ..,:lxOKXNNNNXNNNNO'     .lkoc;'.          .lKNNNNNNO,                //
//                     'OXXXXXXOloKKo:ldOKXXXXXXXXNXK0xlc;.             ....      .dXXXXXXXd.                 //
//           .:'        ;OXXXXXXXXXXXXXXXXXXXXKOxoc;..            ..,coxOKKOo:'. .xXXXXXX0l.                  //
//          .lKk'     ..;kKKKKKKKKKKKXXK0kdlc,.....              .oKKXXKKKKKXX0kokKKKKKXO;                    //
//          l0KKx;,cldk0KKKKKKKKKKK0xl:,....':coxOOd:'           .kKKKKKK0KKKKKKKKKKKKKx.                     //
//         'kK0KK0KKKK00KKK000KKK0Kk,.,:coxO0KKKKK0KK0x,.        ,OK0K0KO:,cdO0KK0KKK0l.                      //
//         .xK00000000Oxoc:':k00000OkO00000Okdl::x0000Ko'.       :00000Kx.   .,cddoc;.                        //
//         .o00Okxoc;'..    .x0000000Okdl:,..   .o00000o,.       l000000o.            .';cl,                  //
//          ,c;'.           .x0OOOOo,..     .   .o0OOO0o;. ..   .o0OOOOO:       .';cldkO0k;                   //
//                          .dOOOOk,  ..';cod'  .lOOOOOxdooc.   .xOOOOOk, .';cldkOOOOOOko'                    //
//                          .dOkkOk; .okkOkOx;.':dOkkkkkkd,     ,xOkkkOx'.oOOOkkkkOkxl;.                      //
//                          .dkkkkk; 'xkkkkkkxxkkkkkkkkdc.      ;kkkkkko. ,:ldkkkxl'.                         //
//                          .okxkkx; 'dkkkkkxo:,;okkkxko;.      ckxkkkkc    ,dkkkxl.              ..          //
//                          .okxxxx; .dxxxxxx,  .ckxxxkl,.     .lkxxxxx;  .lxxxxxxxo'             :;          //
//                          .oxxxxx; .dxdoc:,.  .cxxxxxl,.     .oxxxxxd' 'dxxxxxxxxx;            ;d,          //
//                          .lxdddd; .''.       .cxdddxl,.     'dxdddxo. .;,:dxdddxc.           'od'          //
//                          .lddddd;            .cdddddc,.     ;ddddddc.   .:dddddo,....',,.   .ldo.          //
//                          .lddddd;    .;'     .:dddddc,.     :dddddd;    ;odddddollooddo;.  .cddl.          //
//                          .cdoood;     ;o:.   .:dooodc'.    .cdoooool,. .:ooooooooooooo:,;:cooodc.          //
//                           .,cooc.     'ooo:..,loooooc'.    .looooooool;,;cooooooooooooooooooooo:.          //
//                              .'.      .;looooooooooo;.      .:loooooooooooooooooooooooooolc:,'..           //
//                                         .;lollloool;.         .;lolloollllolllloooolc;,'..                 //
//                                           .,cc:;'..             .,clllllllllllc;,'..                       //
//                                                                   .':llc:;,'..                             //
//                                                                      ...                                   //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ZKXED is ERC1155Creator {
    constructor() ERC1155Creator("ZKX_ED", "ZKXED") {}
}