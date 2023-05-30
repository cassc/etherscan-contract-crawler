// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Saint MG Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                  //
//                                                                                                                                                                                  //
//                                                                                                                                                                                  //
//                                                                    'odlc:;,,,,,,'''''''''''''''''',,,,,,,;;:cldl.                                                                //
//                                                                     ;0MMMWXklc::::::clxKNNXNX0dlc:::::clONWMMWO'                                                                 //
//                                                                      :NMMKc.           lXNMMK;          .lXMMK,                                                                  //
//                                                                      ,KMMd.            ;kKMMk.           .kMMO.                                                                  //
//                                                                      'dKWXc            ,xKMMk.       '. .oNW0o.                                                                  //
//                                                                        .oX0'           ,xKMMk.       'l;cXKc.                                                                    //
//                              ..                                      .looKO.          .cOXMM0c,,..  .:odd00ooc.                                     .                            //
//                              ;l.                                     ,OX0d'       .;cclkKNMMWNWNX0xl';O0;,xKXk'                                    .,.                           //
//                              :d.                                      ...       .lko,. ,xKMMO::xXMMMXk0d.  ...                                     ';...                         //
//                              :d.                                               ,OWd.   ,xKMMk.  'xNMMXo.                                           ,,':.                         //
//                              :d.                                              .OMWl    ,xKMMk. .;xNNx,                                             ,'';                          //
//                      .;lc:;'.cx'                                              :XMMx.   ,xKMMk..oNMK:.                                              ,',;                          //
//                      .cx000KO0XOdddd;.                                        :XMMNd.  ,xKMMk..OMWo.;c;.                                           ,,:;                          //
//                      ..',;;;;dOocclolc;,.                                     .kMMMWKo':xKMMk. cKWkoKMK,                                           ,;l:                          //
//                              :d.     ....                                      'OWMMMMNKXWMMk.  .cxkOx;.                                           ':l;                          //
//                              ld.                                                .cONMMMMMMMMXd;.                                                   .co;                          //
//                             .ox.                                                  .,lkXWMMMMMMWKxc.                                                .ld,                          //
//                             .od'                                                      .o0NMMMMMMMWKl.                                              .ox'                          //
//                             .lo,                                                       ,xKMMKx0WMMMWO'                                              lx'                          //
//                             'cl,                                              'looxl.  ,xKMMk..c0WMMWd.                                             :d'                          //
//                             ,;l;                                            .cX0:lXO'  ,kKMMk.  .kWMMO.                                         ....:x;...';:;,.                 //
//                             ,,c;                                            ;KM0'.,.   :0XMMO' . ;XMMx.                                     ..;loxkk0X0OO00x:..                  //
//                             ,,;,                                            :NMWd..:xOkXWMMMW0Ok;;0MK;                                      .;dxdoocdOl''''.                     //
//                             ,',,                                            .xWMW0xddoooooooooodokNK:                                        ....   ;x'                          //
//                             ;',;                                             .lKWMNkl,.       .,lxo.                                                ;x'                          //
//                             ,,.,.                                              .:dk0XX0Okkxdollc;.                                                  ;x'                          //
//                             ';.                                                    ..',;;;,'..                                                      ,d'                          //
//                             ...                                                 .       ..     ...                                                  .,.                          //
//                                                                                .dd.   .dOd'.':;;:lo'                                                                             //
//                                                                                 oNx. .dNMd.:k;    ,.                                                                             //
//                                                                                .odxx'cokMd.dk.  .;:,.                                                                            //
//                                                                                .dl'kKl.dMk.;Od,..lKo                                                                             //
//                                                                                'l:.':..col,..:c:;:c'                                                                             //
//                                                                                                                                                                                  //
//                                                                                          .:.                         ',                                                          //
//                                                    .'.                          .''..';lx0Kxoc'..     ..            .dk. 'cc:'.                                                  //
//                                                    .:lc,.         .:oc.        ;xc:cl0WXKkl::,;x:   .lkkxl'  .,:.   .xd  oXkdko.                                                 //
//                                                      lXkllc:;;'.  .o0K0d'     .xK;  .oX0x;    :Xo.  lNO;:Ok' 'OWO'  ,0l  :Ko..c,                                                 //
//                                                     .:Od.,c;...   .l0llkkc.  ..kXc.  'k0k:  ..lNx. .kMx. '0O..ONKOo,lXc .;oOx,.                                                  //
//                                                     .:x0l...      .o0;  .lO:. 'ONl.   cOk:.  .oWO. .xWx. 'OK,.k0:dXO0X; :x..:xx'                                                 //
//                                                       '00c,.     ',c0l .cxd'  .kNc    ;0Xl    cNx. .:OO' ;KO'.kO..lKW0, o0,  ,0o                                                 //
//                                                       ,0Kdoc;;;,',cd0Kkko,.    dX:    ,kO:    ;Xx.  .cdc;xk:..ol.  'OO. 'xOc,dKc                                                 //
//                                                        .;,',;;,,.  ,odc,.      ;o.    ...     .o:    .,:oc'.  .     ld.  .,coo;.                                                 //
//                                                                                 .              .                    ,;                                                           //
//                                  .:ll;.           .:o:.                                                                       .co,            .:ll;.                             //
//                     ...         .cOXXNOclocdc.     ,kNd......       .,c:,.       .                ..       .;cc'.       .....'kNd.     .loldllKNXXk:.         .'.                //
//                   .:xd'         .':;oNM0okNX:..;:lxKWNk;,:cllolllc;'';;:ldc. ;l:lOl.             .oOc:o' 'ldc;;,',:cllloolc:,cOWN0dl:;..lXXxoKMKc;;.          ,xx;               //
//                   .d:             .:ONWk.'OKkxOKK0Okdooodxoc:cloxkkxooc'.'dkdOXXWMKl.           'oXMWXNOdOo..,lodxkkxocc:cddoooodkO0K0kdOXx.'0WXk,             .lo.              //
//                    ;d:.       .':okOc;l:,codccodkl. .....:k;  .';clcldxxdc,dOxkXMXc.             .oNMKxxOl;oxxxdcclc;..  cx;..... .okdl:ldl:,:c;oOkl;..       .cd,               //
//                     'oxxdoodxk0NWXd,..;ll:'..,,.'' .'.   .,. .....':dl;cdkkxdloXMx.               .OM0lodkOxoc:oo;...... .,.   .'..''.,'..,clc,..;xNWX0kxdoodxxl.                //
//                       .;clllkWMNKx:.;ooccc' .'.   ..,,,;,,'...    .cOc .,cok0koOW0'               ;XWxoO0xl:' .oO;     ...',;;;,,.    .'  ,ccldo,.ckKWMNxllc:,.                  //
//                           'dKXKXNKxk0l,,.    ..';;:cclodxOKK0ko:.  ....'.,:cdOdlkXO,   .,,..,.  .:KXxlxOo:;'.'.... .'cdk0K0kxdolc::;,'..    .,,d0xxKNXKXKl.                      //
//                           .,,.,ll:xNx....  .',,'.'''...  .'lkKNN0x:......':l:xOoodkko;.:Ox,:x;.:dkxdldOo:l;.......ckKWN0x:..  ...'''.',,'.  ...'OXo:oc'','.                      //
//                                  ,0K,  ...,;'..:xd;''',;;.  ,okkkO0k,   .'od;l0d;:',oxxk00xk0kxxl,,c:xO::dl.   .:O0OkOxl,  .;;'''':xx;..';'...  cNk.                             //
//                                  cNK, .;cdl..'.:k:     .cd..;l;.'ddkO;  .;c,,oKd,;....',;,..,,....',,x0c,,c,  .cOxdo..:l, ,d;      lx,.'..od:,. cNK,                             //
//                                  ;0XOokOkOOo:'  ..    ,:c0d.''.. :kokd.,:..:d0Nc,c,.            ..;c'dNOo:.':''xxdk, .',.'kO::'    .. .,:dOkk0xd0Xk'                             //
//                                  .cdlc:oXNNxoxc'.    .o0O0KKKKxc:k0okx,dNXNNNWO;ld,,.           .,;xc:KWNNXNNl,kdoKx:lkKKKK0OOc     .'lxlkNN0c:cod:.                             //
//                                   .;lloOWM0c:l:;.     ..';0MWWk:dOllko..cd0KXNkdKd':.           ';'k0dONKKOo;..dkcoOlc0WWMk,'.      .;:l:lXMNkolc,.                              //
//                                     .,clol;.             .xWKl,',,;od,   ;KWXXXWXc:l.           .l;oNNXXXWO'  .:xl;,'',oXWo.            ..:lll:'.                                //
//                                                           'kXOlcodol'    .,,lKMXdok:            .lklkNM0:,,.   .,lddlco0Xd.                                                      //
//                                                           ;ollolc,''.     .cKWKxx0d.             'k0xkXW0:.     .,';clollo,                                                      //
//                                                           ..       ;c,'',:kNMX0KXk;              .cOX00NMXx:''';l,       ..                                                      //
//                                                                     .,:ox0NWKXXxoo;.             .:doxNKXWNOdl:,.                                                                //
//                                                                        'dKWkck0c,cc.             'c:'o0dcOW0l.                                                                   //
//                                                                       .cKW0:::''.                   .''c:lXW0;                                                                   //
//                                                                       .;;cll:.                         .cllc;,.                                                                  //
//                                                                          ,dkc                          .lOo'                                                                     //
//                                                                          c0Kx.                         'OXO;                                                                     //
//                                                                          lNX0:                        .lKXX:                                                                     //
//                                                                          cd,..                         ..;x;                                                                     //
//                                                                          ,d;  'c;.                 .::.  :d.                                                                     //
//                                                                           ;kdl0WK:                .lXWklxx,                                                                      //
//                                                                            .ldxo:.                 .cdxd:.                                                                       //
//                                                                               .                       .                                                                          //
//                                                                                                                                                                                  //
//                                                                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SAINT is ERC1155Creator {
    constructor() ERC1155Creator("Saint MG Editions", "SAINT") {}
}