// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LAPRISAMATA ed
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                       ...''.                  ''...                                        //
//                                 .,:oxO0K0xc.                 .:x0K0kdl:,.                                  //
//                             .;okKWMMMNkc.          .;:.         .ckNMMMWKko:.                              //
//                         .:ox0NMMMMMXd'            .;ll:..          'l0WMMMMWKxoc'                          //
//                      .ckXWMMMMMMMKo.            'cccllccc,.          .:kNMMMMMMMNOo,                       //
//                    .lKWMMMMMMMMKl.          .c:;cxxl::cxxl:::.          ,xNMMMMMMMMNk,                     //
//                   :0WMMMMMMMMNx.            ':;cxkolcclokx:;:.            ;OWMMMMMMMMNd.                   //
//                 .xNMMMMMMMMMK:        ;;.';;:::lodxdc:oxdoc;;;;;..;.       .lXMMMMMMMMMK:                  //
//                'OWMMMMMMMMM0,        cxd,c0OxloOKN0odxoONKOolxOO::xx:        ;0MMMMMMMMMNd.                //
//               .OMMMMMMMMMMK;      ..:xldc,kNxdXMMWkcodokWMMXoxNd'lkxx:.       ,0MMMMMMMMMWx.               //
//               oWMMMMMMMMMWl       .;dxoxd,:0xxNN0xdlcllxOKWNxld,,xkkko;.       cNMMMMMMMMMWx.              //
//              ,KMMMMMMMMMMX;   .;;,;:kOddxc.l0kOOolllddlodk0kod;.okddOd;,';;.   ,KMMMMMMMMMMNc              //
//              cNMMMMMMMMMMX;   ;KNXOcl00Okc..d0K0dodxkkkdox0Okd..x0O0Xd:OXNNc   ;KMMMMMMMMMMMx.             //
//             .dMMMMMMMMMMMWO,  ;XMMMO:dXXd,. :Okdodxc,,cdooxxk: .;xXNkcOMMMWl  ,kWMMMMMMMMMMMO'             //
//           ..;KMMMMMMMMMMMMMNOoxNMMMWo,xKocx,.kXolddkOkdodldXx.'xclKx;lNMMMWOoONMMMMMMMMMMMMMNl..           //
//         .,. .OMMMMMMMMMMMMMMMMMMMMMMOloOKkxl.lNXXKdlllldXNNNc ,dkKklcOWMMMMMMMMMMMMMMMMMMMMM0, .'          //
//         ,,   dMMMMMMMMMMMMMMMMMMMMMWkcoooxXx.;KNWMWXKXNWMWNK;.xXxooockWMMMMMMMMMMMMMMMMMMMMWd   ;'         //
//        .c'   ,KMMMMMMMMMMMMMMMMMMMMWc.;d:.:d'.OMMMMMMMMMMMMO.'o;.;o:.lWMMMMMMMMMMMMMMMMMMMM0,   ;c         //
//        'l.    ;KMMMMMMMMMMMMMMMMMMMO:cdo' .c; dWMMMMMMMMMMWo ;;  .ldc:OMMMMMMMMMMMMMMMMMMMK;    ;o.        //
//        'o'     'OMMMMMMMMMMMMMMMMMKllc;:'  :;.ckNMMMMMMMMXxc.;,  'c;cllKMMMMMMMMMMMMMMMMM0,     :d.        //
//        .xc     ,0MN0XWMMMMMMMMMMM0:odlld0o,o:,c'xMWX00KWMd,o,;:,x0dllooc0MMMMMMMMMMWNOkXM0,     dd.        //
//        .x0,   ,0MK;..:dKWMMMMMMMNdckkdlxdckk,,':XW0l::l0WK;,,'xx:dxcdxxcdNMMMMMMMNkc.  'OWK,   lKl         //
//         cNKl..kMWl     .l0WMMMMMWkc',clo',kc';'kMWNXKKKNMMx,:':d,:xcc,'lOWMMMMMWO;      '0Mk',xNK,         //
//         '0MMX0NMXl'..''',lXMMMMMWXd,;,,c;;'.:clOWMMMMMMMMWOcc:..,:c',,,xNWWMMMMKc''''..';OMNKNMWd          //
//          lWMMMMWWWNNNNNNWWMMMMMNNMNx,      .;:;o0NMMMMMWKxc;c,       'xNWWWMMMMMWWNNNNXNNWWMMMMK,          //
//          .kMMMWx;codkOKWMMMMMMMWWMMMNx,    ..:l:cdONWWNkl;;l:..    'oKMMWWWMMMMMMMN0kdlc;:OMMMWl           //
//           ,0MMMO.     .;d0NMMMWWWMMMMMNOxxk0KKX0kKXNWWNX0OKXKK0xodONMMMMWNWMMMMN0o,.     :XMMWx.           //
//            ,0WMWk'       .;OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO,.       cKMMNd.            //
//             .cONWXd;..    .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.    .'ckNWKd,              //
//                ;kWMWX000Ok0WMMMMMMMMMMMMMMMMMMMMMWNWMMMWWMMMMMMMMMMMMMMMMMMMMMW0kO00KNMMXd.                //
//               ;ONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKKWWXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk;               //
//              cXMMMMNOkxk0NMMMMMMMMMMMMMMMMMMMMMMMMKxdddKMMMMMMMMMMMMMMMMMMMMMMMMWKkxk0NMMMMNl              //
//             .OMMMXo'    .cXMMMMMMMMMMMMMN0OOKWMMMMk,...xMMMMWKOOXMMMMMMMMMMMMMMXc.   .,xNMMMK,             //
//             ;XMMNc        cXMMMMMMMMMMWWO:oc:k0XMK; .. :XWXXd,l:cKMMMMMMMMMMMMXc       .xMMMNc             //
//             ;XMMK,         'dOdkWMMMMMMWNOkxlckN0;  ..  ;OKkolxdkNMMMMMMMNkOXk,         oMMMN:             //
//             .OMMWx.            .kMMMMMMMMWXKdoxdc,...'. .;odoo0XXWMMMMMMWd...          ;0MMMO.             //
//              'kNMWKo,.          ,0MMMMMMMWNK0KXXKx:;odc:d000OkKNWMMMMMMM0'          .:xXMMNx'              //
//                ,lkXWWKkoc;.      ,KMMMMMMNKX0dodKMKxkkkKM0dooxKXNMMMMMMX:      .;cokXWWXkl'                //
//                   .:d0NMMMK;      ;KMMMMMWXXKddONMMMWWWMMXkldk0XNMMMMMK:      :XMMMW0d:.                   //
//                      .cXMMN:       ,0MMMMXxxOXWMMWNNWWNNNWMNX0kd0WMMW0,       lWMMNl.                      //
//                      'dNMMO.        .xNMMMNKNMMMMWNNNNNNNWMMMWXXWMMXd.        ;XMMNd.                      //
//                   .ckXMWXd'           :KMMMMMMMMMMMMMMMMMMMMMMMMMWk,           ;ONMWKd;.                   //
//                 ;kXWWKx:.              'OWMMMMMMMMMMMMMMMMMMMMMMWd.             .,lONMWKx'                 //
//                 lNM0:.                  oWNNMMMMMMMMMMMMMMMMMMNNWo                  'c0MX:                 //
//                 .ONc                   ,Ok,'o0WMMMMMMMMMMMMWOl';k0;                   cNx.                 //
//                  :k,                   ...   .:xKWMMMMMMWKx;.   .'.                   ,k;                  //
//                   .                             'kXNMMNXk'                            ..                   //
//                                                 .l,:O0c,c.                                                 //
//                                                     ..                                                     //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LPM is ERC1155Creator {
    constructor() ERC1155Creator("LAPRISAMATA ed", "LPM") {}
}