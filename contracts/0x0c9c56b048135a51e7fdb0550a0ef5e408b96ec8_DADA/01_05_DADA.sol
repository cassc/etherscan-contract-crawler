// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DADARA Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                 ......                                                     //
//                                        .,;;:cdk00KKK0000OOkdl:;'.                                          //
//                                  .,cldOXWWMMMMMMMMMMMWMMMMMMMMWNK0xl:,.                                    //
//                              .,:dKWMMMMMWNXOxolllc::;::ccllox0XWWMMMMN0dc,.                                //
//                           .cOXWMMMMNKkoc;'.    .:odl,..      ..,:loONMMMMWKd,.                             //
//                        .:xXWMMWN0o:,'...      cKN0kKNXO;           .':lkXMMMN0d:.                          //
//                      .c0WMMMXkc'..;dOKKKO:   :XWO;'cKMMK;               .cONMMMWOc.                        //
//                     ;kWMMW0l'  'dKXkl;:OW0' .xMWK000XWWWk.     .''.   .....;oONMMWO;.                      //
//                   'xNMMW0c.   .dWM0,.,oKWO. .OMK:...;o0MX;   .lOOxxxxkOkxxd:..:OWMMNOc.                    //
//                 .oXMMWO:.      .oXWXKX00XXOl,lOc.    .c0x'   lNO' .'::'. .l0d. .dXMMMWO:.                  //
//                :0WMMKl..:oddl;.  ;0WW0,..:lc...       .'.    lNXd;...    .:K0'   'oKMMMNk'                 //
//              .oXMMWk,.cKXklxXWKkc.'xNXc      ;kl.   .ck0l.    ;xXWX0OkkkO0XKc.     'oKWMW0:                //
//             .xWMMNd. .OMO,,kNKxxK0c.''.     .OWNO, 'ONK0Kx.    .dNd'',,oXWk'         'xNMMXl.              //
//            .dWMMXl.   lNN0XXd.  .;'        .dNkoXXx0X0c.lKx.   ,0Nxc:,':0MO.          .oXMMNo.             //
//            lNMMXc     .oNMNl        ,;.    cNX: :KMMk:.  lXO:;oKXo,:lxOKWMO.            :KMMNx.            //
//           cXMMK:    .  .cXW0;      'OWKl''lKMO.  ,0Xc.   .oNWWNNKl.   ,OMNl              :KMMWx.           //
//          ,KMMXc .;okOOkl';xKl       ;KMWNNX0x;    .,.     .dWK:,oKO:..dNWx.               cNMMNo           //
//         .xWMWd.,kN0l,:0WO' .  'l:..'dXWXkc'.   ....        .kXl  'xXXKWWx.                .kMMM0,          //
//         :XMMK,'OMK;   :XNl    cKWX0XWXd'   .;ok00O0Oxoc.    'OXo,;dXMW0c.                  lNMMWd.         //
//         oWMMk.cNMXdc:;lKMx.    .lKMW0;   .o0Kkl;,',:dk0Kd'   ;XWWWWXkc.    ..','..         '0MMMk.         //
//        .OMMMd..ldxkO00O0O:      ;KMK;   ;0Xd'         .c0Kl. .xWWO:.   .;ok0KKK0O0Oxc.     .OMMMK;         //
//        ;KMMWo        ....   ...,kMNl   ;KNo. .';clooooooOWNl  lNWo   .cONXkc::;,,,ckXXo.    oWMMWx.        //
//        lNMMNl     ..;codd; :0XXXWMK,  .dWKookKNWMMMMKx0NOOWk. ;XMx. 'kNXd;:oOKKK0d;.;OWK:   cNMMM0,        //
//        oWMMNc  .;dOXWN0kd, .:lokNMK,  .dWMN00NMMMMMKl,dO;cNO. ;XMx.'OWK:,xNN0dookKk' 'OMK,  cNMMMK,        //
//        lNMMWo .dNKokW0,        .kMNl   :XWk'.:kNWXKOkkx;.xWO. :XWo.dWX:'kWKc.    ..   lNWo  cNMMM0'        //
//        ,KMMMx.'0M0:oN0,       .'xWM0,   :KXx,  ':llc,.. cXNl .xWX:.OMx.:NWd.          ;KMx. cNMMMk.        //
//        .kMMMO. ;ONNXWNd,'.  .o0NWWWW0c.  .lOKOo:,...',:xXXl. :XWk..OWx.;XMO;    .,;.  ;KWd. lNMMWo         //
//         oWMMK;  .,lx0XNNNx. .:doc,:OWWKd,  .'cxOO0O00K0kl'  .OWX: .xWK;.lXWNOdox0NK; .dWX: .kMMMK;         //
//         '0MMWx.     ..,;;.        .oNMMMNOo;.   .......    .dWNo.  'OWKl',lOKNNXKx,.'dNXl. lNMMMx.         //
//          lNMMK;       'cool;.    ;OWNxcxNMMWXOxl:'.        .lKNk'   .dKNKxlcc::;,,cxXNO;  'OMMMNc          //
//          .OMMWk.    .dXN0O0XKo. .cOk; .oNMMMMMMMWN0koc,      .oKKc.   .:x0NWNXKKKNNXOc.  .oWMMWk.          //
//           ;KMMWO'   lNWd. .;kNKc.     cXMWXkxxOXWMMMMMNd.      ,0Xo.     .';clool:,.    .oNMMMX:           //
//            ;KMMW0,  cNWo   .oNXd.    :KMXl.    ;KMWXNMMNx.      ,0Nl...                .lNMMMXc            //
//             cNMMW0; .dWXl,l0Kx,    .oNM0;     .dNKl.:xKMWx.      :XNK00Oxc.           .oNMMMXc             //
//             .c0WMMNo..lKWNKd'     .xWWO,     .dN0,    :KMNc       ,c;,,:o0Kx'        'kWMMW0;              //
//               .dNMMWO; .co,     .:0WNd.      ,KW0:.    cXMk.             .dNK:      :KMMMNd.               //
//                .lXMMMXo'       'xNWK:..','    'cOXx.   .dWNl   ,xOxl.  .,lONXo.   .dNMMMKc                 //
//                  'xXMMWXd,    cKWMXl,okOXXl     .xNo.   ,KM0, .ONOKWKxkKXKkc'   .lKMMMNk,                  //
//                    ,kNMMMNx,  .cxKNXXO;.xM0,     cNO.   .dWWklkNO''kX0xl;.   .,xXWMMNx,                    //
//                     .:OWMMMXx:'  .;oo' '0MWK0Okxx0WO'    ;XMWWNKx. ...     'lONMMMWO;                      //
//                       .cONMMMWNOo,     .lxO0KKXXNNXd.    .:l:,..       .,oONWMMMXx:.                       //
//                         .'lONMMMMNkl:..     .......                ..:d0NMMMMN0o'                          //
//                            .,o0NMMMMWX0xoc;'..               ..,cok0NWMMMWXOo,.                            //
//                               .,lkKNWMMMMMWNXK0OxdoolllloxkOOKXWMMMMMWX0xc.                                //
//                                   .':ok0KNWWMMMMMMMMMMMMMMMMMMMWWNKOd:..                                   //
//                                        ...,;clldxkkkkkkOOkkkxoc;,..                                        //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DADA is ERC1155Creator {
    constructor() ERC1155Creator("DADARA Editions", "DADA") {}
}