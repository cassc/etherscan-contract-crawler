// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alejandro Farias
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                        //
//                                                                                                                                                        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM++/\ |_ /= /\++MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMiKooXiMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                            //
//    MMMMMMMMMMMMMMMMMMMMMWWWMMMMMioooookiMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMMMM                            //
//    MMMMMMWNNNWMMMWpXqpXXqpXxpd0Wioo00oxiMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                            //
//    MMMMW000000000:P.        .cllkd:00:dOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO000000000O0XWMMMMMMMMMMMM                            //
//    MMMMK; .',''oo.          .dll  .00                                                                        +++0MMMMMMMMMM                            //
//    MMMMO.      :l            oo   .00::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::o>MMMMMMMM                            //
//    MMWWNo.   .'do            :x;. .00                                                                        +++0MMMMMMMMMM                            //
//    MMMWMW0dloONWd             'dl.........::cdxxdc;;:cc:;;:lOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO000000000000000NMMMMMMMMMMMM                            //
//    MWWMMMMMMMMMMO.             ;  pdc;'.......''...,;::::;:oc:OWWMMMMMMMWNK000XNWMMMWXXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                            //
//    MWMMMMMMMMMMMWx.           c   .              ':loool::cc..;clodddol:,......';cdk00kdc::cldkKNWMMMMMMMMMMMMMMMMMMMMMMMMM                            //
//    MMMMMMMMMMMMMMWo         oW  :dxc.          ..,::cldxo,                          .,lxkxo;.  ..;lkKWMMMMMMMMMMMMMMMMMMMMM                            //
//    MMMMMMMMMMMMMMMx.        .x  a/  pc.        'codoll:.                                .,lkOkl'    .;o0NMMMMMMMMMMMMMMMMMM                            //
//    MMMMMMMMMMMMMMMx.        .x  a dAWX;  ,c,    .,ldkx,                                .''.':dOKOl.    .;dXWMMMMMMMMMMMMMMM                            //
//    MMMMMMMMMMMMMMMx.        .x  pPkMMX;  :Oc  ..';;,'.    .colcc:,.                    .;oOKOlcoxkx:.     .oKMMMMMMMMMMMMMM                            //
//    MMMMMMMMMMMMMMMx.        .x   d;xOop  .;.       .,:cc:oxl;'.',,,..                     .;odo;.  .        .dXMMMMMMMMMMMM                            //
//    MMMMMMMMMMMMMMMd           b  /q..\          ':cclccc:,.                                  .;dko,           ,OWMMMMMMMMMM                            //
//    MMMMMMMMMMMMMMMd           b  A,q          ;c:'                          .'.             .''';okx:.         .dNMMMMMMMMM                            //
//    MMMMMMMMMMMMMMMd           b  "     .cxd''ol.                         .loc,.             .;d00oo0N0c.        .lXMMMMMMMM                            //
//    MMMMMMMMMMMMMMMd           b  ,;;;,lKW0;:x;                          ;Od.               .,'';loc,,co:.         cNMMMMMMM                            //
//    MMMMMMMMMMMMMMMd           ol.....;:c';O;              '.          ;Oo.           ..   .x0xlokKk,         .;,   oNMMMMMM                            //
//    MMMMMMMMMMMMMMMd                      .xk.            'c'          ;0o.      .'.  .ckxl:..cd;';lk0d.        .od;.xWMMMMM                            //
//    MMMMMMMMMMMMMMMo                      .xd          .;cc.         .cKd.       :0klc,.lX0ooook0l.  .:c.         :OxdXMMMMM                            //
//    MMMMMMMMMMMMMMX:                      .xd..'',,,;;;:;.        ..:xxxo',oll;. .xx';lookKo..,lOXd.               ,0NNMMMMM                            //
//    MMMMMMMMMMMMMWx.                      .:olcc;,,''.  .:oxkOOOOOOXNo. ;xx,.'coc.cO'  .,o0Nd.   ,o:                ,0MMMMMM                            //
//    MMMMMMMMMMMMMMNx.                                .cxXWMMMMWKOo,oNO.  ..     ;lxK:     .dXd.                      ;KMMMMM                            //
//    MMMMMMMMMMMMMMMMKl.                          .;lkXWMMMMMXk:.   .xWd.          :0l       oXo               .,.     lNMMMM                            //
//    MMMMMMMMMMMMMMMMMW0doc:,'..            .';cdkXWMMMMMWKxc.       ,KX:     ',    :k,      .dXc               ,dd,   .OMMMM                            //
//    MMMMMMNKXWMMMMMMMMMMMMMWNXK0OkxxdddxkO0KNWMMMMMMNKkl;.           oWx.    'd,    ox.      .kK;               .xKd.  dMMMM                            //
//    MMMMMWXo',:ldxOKXNWMMMMMMMMMMMMMMMMMMMMMMWNKOxl:'.        .,::.  ;KK,    .xd.   'Ol       ;XO.               .dNO, lWMMM                            //
//    MMMMMWMNd.     ..';:cloddxxkkkkkkkxxdolc:,..           .;okdc'   .ON:     dK,    lO'       dNo                .xW0:xMMMM                            //
//    MMMMMMMMW0:.                                       .;lkXKd,      .xNc     oWl    ,0l       ,KK,      ,,        '0WXNMMMM                            //
//    MMMMMMMMMMWOc.                                 .;lkKWNOl.        .xN:     oMd    .xx.      .xWo      .dc        lWMMMMMM                            //
//    MMMMMMMMMMMMWXxc'.                       ..;cdOXWWKxc'       .:, 'OK,     dMd     o0'       cN0'      :0c       ,KMMMMMM                            //
//    MMMMMMMMMMMMMMMMN0xl:,...       ...',:ldk0XWWX0xl,.       .cxkl. :Nx.    .kMd     oX;       ,KN:      .kXc      .kMMMMMM                            //
//    MMMMMMMMMMMMMMMMMMMMMWNK0OOkkkOO0KXNWNX0Oxoc,.          ,o00d;  .OX:     '0Wc     oN:       '0Md       lWX:     .kMMMMMM                            //
//    MMMMMMMMMMMMMMMMMMMMKkddxxddddoolcc:,'..             .ckX0c.   .dNd.     cNK,     dN:       .OMk.      ;XM0'    '0MMMMMM                            //
//    MMMMMMMMMMMMMMMMMMMMNkl'.                        .,lkXXk:.    .xNk.     .kWd.    .xX;       .OMO.      ,0MWd.   :NMMMMMM                            //
//    MMMMMMMMMMMMMMMMMMMMMMMN0d:'.               ..;cx0NXkc.     .:0Wk.      cNK,     '0K,       'OMO.      '0MMK,  .kMMMMMMM                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWKOxolc:::::ccodk0XWN0d:.     .;kXNNo.      '0Nl      lWk.       ,KMO.      ,KMMWl  lNMMMMMMM                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdc'.     .;o0NWXO;       .kNd.     .OWo        cNMk.      :NMMMd.cXMMMMMMMM                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNOc;,',,:cokKWMWO:'.       .xNx.      oWX;       .dMMd       oWMMMkdXMMMMMMMMM                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWMMMMWXx;.         'kNx.      :XMx.       '0MN:      '0MMMMWWMMMMMMMMMM                            //
//    MMMNKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc.           ;0Xl.      ,0MK;        oWMO.      oWMMMMMMMMMMMMMMMM                            //
//    MMMXx:;coxOKXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xl,.            .dX0;       ,0MWo        ;KMWl      :XMMMMMMMMMMMMMMMMM                            //
//    MMMMW0c.   ..,;cldxkO0KXNNWWMMMMMMMWWWNXK0kxoc,..              .lKXo.       ;KMWk.       .kMMO.     ;KMMMMMMMMMMMMMMMMMM                            //
//    MMMMMMWKo'           ...'',,;;::::;;,''..                    .lKXx'       .lXMM0'       .dWMX:     :KMMMMMMMMMMMMMMMMMMM                            //
//    MMMMMMMMMXkc.                                            .:x0XXx,        'xNMM0,       .oNMNo.   .oNMMMMMMMMMMMMMMMMMMMM                            //
//    MMMMMMMMMMMWXkl,.                                     'cxKNKko'        .lKMMM0,       .dNMWd.   ;OWMMMMMMMMMMMMMMMMMMMMM                            //
//    MMMMMMMMMMMMMMMWKko:'.                           .,cdONWXx:.         .:0WMMWk.       'kWMWd. .;kNMMMMMMMMMMMMMMMMMMMMMMM                            //
//    MMMMMMMMMMMMMMMMMMMWNKOxoc:,'....     ....',:lox0XWWN0d:.          .c0WMMMNo.      .lXMMNd..cONMMMMMMMMMMMMMMMMMMMMMMMMM                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKK000O000KKXWWMMMWNOdc'.           ,dKWMMMW0;      .:0WMMNklxXWMMMMMMMMMMMMMMMMMMMMMMMMMMM                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOdl;.            .,lONMMMMMNd.     'l0WMMMMWNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0xol:;'.            .,cxk0WMMMMMMNk,   .,lkNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                            //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMWMMWKxoc;'........';:ldkKNMMMMMMMMMMXd::cdkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM AlFa C721                            //
//    MMMMMMMMMMMMMMMWWWWWWWWWMWWWWWWWWMMMMMMMWNXXKKKKXNWWMMMMMMMMMMMMMMMMWNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM AlFa-S ERC721                            //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                            //
//                                                                                                                                                        //
//                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ALFA is ERC1155Creator {
    constructor() ERC1155Creator() {}
}