// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Game Overture
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    ..:o:.                                                                                                                      //
//    .:OXKd,.':,.                                                                                              ..                //
//    ,xXNNX0kxl'                                                                                            .';dxl,......        //
//    lKNNWWNNKd,                                                         .                                 .':kNNNKo'...,,.      //
//    NNWWWWNNXd.                                  ...                    ....                            .,' .lXNNNXx,':ll,      //
//    WWWWWWWNNd.                                .....                 ........                          .cl;',dXNNNNXkoxkd,      //
//    WWWWWWWNNx.                               .............       ............                         .dKKKXXNNNNNKxoxxl.      //
//    XWWWWWWWXo.                              .''''''''...............',,,,,'',.                        '0XkkXNWNOddcclol'       //
//    0WWWWWWWX:                              .;;;cloooolc;,'......'',,;;:ccc;,l;                        lXNXXNWWNOoool::.        //
//    lXWWWWWWNo.                             .occkOOOOOkxoc:;,,,,,,,;;::coxd;:dc.                      ,0WWWNNWWWNOodo;.         //
//    .lXWWWWN0:                              'kx:dOxdoooolc:;,,,,,,;;;:::ldlcod:.                     .dNNWXdc0WWNkxOx;.         //
//    .lNWWWWO:.                              .dx;:ol::;;;;,,,,,,,,,,,,,,,;:cllc;.                     .kWN0l.,0WNNNWNN0l.        //
//    ;xXWWWNk'                ....           .:oclxdl:;,,,,,,,,;;,'....'',,:c::'                       'cl,. .oXWWWWWWKo.        //
//    .,oXWWNd.              .ckkxl,.          'cooc,'.....,clc::,.. .':clllc;,,.        .        .    .   .   :KWWWWWW0;         //
//      .xNWWx.              .oXK0Od'          .;:....';:;'.lko::'.  .,ldxdo:,,'        .....  ......         :OXNWWWWWWO,        //
//      .dNWW0:.           ..:OWNKo;.         ..',...',,;;. ;doc:'   .'',c;':oo,      ...                    .kWWWNXXWWW0'        //
//      .lNWWXo.           ..dNWNO'             'c:,,::,:dc':x:':;'..,;,,;;:dxkd'                            'OWWWWNXNNWK;        //
//      .dWWKo'              lNWWKc.            .od;,;ccc:,ckc  .:l:,..';,':lokKo.                           .dNWWNXNXNWW0;       //
//      ;0WXl                :KWWNd.            ,kKkc;;;;,cxd,  .;cc;,;:::;;:ldo'                             ;0WWNXNNNWWWO,      //
//      cXW0,                 :KWNl             .o0Oxo::cokOx;. .,:::;lxdl:;:,.                               'OWWWWWWWWNNK;      //
//    .:0WWK:                 :XW0;               ,ldl,':oxxkdc:,,::;;:cc:,;c.                                'OWWWWWWWNXOd,      //
//    ,OWWNO;.               .dNNKc.                ,o;.;dOkxddo;,:;;:cll;,cc.                               .,0WWWWW0kkl.        //
//    .kWWNKl.               'ONKl.                 .oo,:xOxdo:;'...';:lc':o:.                                ,0WWWWN0d;.         //
//    .dNWNNk,                ,xXo.                  ;x:,cdoo:;;','',;:l:;dkc.                                ,0WWWWWNK:          //
//     :XWNKl.                ;0Wx.                  .lkccolc;,'....',:lloxd;                                 :KWWXKNNO;          //
//     .kWNx.                 ,0WK:                   ;O0Oxdol;'....':odool'                                  ,0WWkc0WXk;         //
//     'ONNx.                 .lXW0;                   ;OK00kxl:,...,cdkkoc,.                                 ;KWWx;kWNXo.        //
//     cXNNd.                 cKNN0,                  .,cxKXKOdl:'.';lloc,;:'                                 ,KWWK0XWNO'         //
//     ;0WNO;                .xNNKo.                  .;:;cdO0xc;;;,,,::,':;.                                 .xWWWWWWNo          //
//     'OWNXd.                cXWNk.                   ,o:,.;xd:,cl;..;,';:.                                   lNWWWWWX;          //
//     .dNNk'                 .kWWk.                   .cc:'.od;',;'.',.,l:.                                   :XWNXNWX;          //
//      oNK:                  .xWNo.                   .:::,.cko;,,'.,''co;.                                   ;XMKx0MX;          //
//     .kWO.                  .dWK;                    .:;;:';dl,;;..,,:c:;.                                   :XWKx0WXc          //
//     ,OWk.                  .oWK,                    'cl:;,:xo;;,..,:;;lc.                  .     .....      :XWOo0WXc          //
//     .xNd.                  .xWXc                  .,,,lo:'ckl;'..,,;:lo;.                 ...   ......      ;XW0oOWK,          //
//     ,0Wd.                  .xNXo..           . ..':l:,lo:;dOc''',',:llc:'.....    .   ......   ....         ,0WOo0Wk.          //
//     .kWx.                ...xWXx;,:;......  ...'ldddl,:o:cOk;.,;'.,;:cl:,,.... ..'''.........  .....        .kWOo0Wd.          //
//     .xXl.                ..,kNKkooxo,...''.....;dxxxxc;loxOc.''...,;::;;c,........';;'..... ...''...        .dW0lkWd.          //
//      :0l.                .,l0N0xxkkd:,'.';::,'':oxkkooc:okd'.'...',::',c:.... .....';c;'..........          .dWOckWd.          //
//      ;0d.                .':xKkdxkkkdc::coolcodxkooxololld:.'.',,,,;';ll'.......'',,'..'',;'....            .xWd'dNl           //
//      :O;                    cx:;:lxkkxddolloxkxxxlcddccldl,'..,;,',';l:;cl;',,',;;;'. .',;,.                 oXd.'xc           //
//      :k'                    co'''',cdooodkkO0OkOOo:clolcl;''..,,.',;:;,:dkdcclolc::;,;cc'..                  :Ko  ''           //
//     .cl.                    ,:.   .,llokOOkdx0kl:;;:oxdl;;;..,'.',;;,;c;:odxxkxoolccldxd;.                   ,0d.  .           //
//     .;'                      .       ..cOk:..d0xc;:oO0x:::..,..'.....,;;cldxddddl;:oxdol'                    '0x.              //
//                                        .','..';:c:'',;,,;'.............';;......',.....                      .kd.              //
//                ..                        ....   ';'.  .''...............,;.     .'.                          .ol          .    //
//    c;;'      :xxoclo:::;,'..',,..,;,.       ..',:c;.  .',,.....''.......'coc;...';.   ,lodddl;,:l:,....','....ll...   .'...    //
//    ;'..      lxc;',;.,:..;'..,c. :l....  .....;oxo:,. .','.....''.......,co;...''c;.  lO0KK0o;..:l:...''......lc.     .....    //
//    .         .' .  . ..  ..  ..  .'  :d,...,;:lddl;'............................'lx;  ';:;;;'.  ...   .       ..      ..  .    //
//                                      :d,...,;:cdoc,..............................lx;                                           //
//                                      ':.  .',;:ll:'..............................;l'                                           //
//             .........................       .......                                  .........................                 //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract nrhmn is ERC721Creator {
    constructor() ERC721Creator("The Game Overture", "nrhmn") {}
}