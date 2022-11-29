// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aqueous Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                    //
//                                                                                                                    //
//                      .kWMMMMMMXo;kWO:,.                      'kK:        .l'                                       //
//                     ,0MMMN0Oxl,.;xd,             ..           'l;         'l.                                      //
//                    ,0MMMWx.     ...     ......                             'c.                                     //
//                   ,0WWMMMXc.       .',,....  ..                             .c.                                    //
//                  '0KONMMNO:.   .....;.  .'lkx:.                              .c'                                   //
//                 .xKokWWOc,...;;''.     'xNXd.                                 .c,                                  //
//                 cNxdNW0dxkld00;       cXXo.                                 .  .c:.                                //
//                .kXokMWXXK0Oo;.        lk,                                  ..   .oo.                               //
//                ;XOoKMNkcc:.          .;.                                   ',    .:l.                              //
//                dNxdNO;.'.            .,.                                   ':.     cd,.                            //
//               cKxcOk.                .,.                                   .c;.    .dX:                            //
//             .l0koOO;'.              .;:.                                    ;x;     'k:                            //
//            ,kKk0WNl,.                ...                                    .o;      :;                            //
//          .oXWXNWWx'.                                                         ',      ;:                            //
//         'OWMWWNKk;                                                            '.     cc                            //
//        ;KMMWWOcxd.                                                            .,,   .o:                            //
//       ;KMMMMXdol.                                                              ,d' .dx.                            //
//      .kMMMMMNKd.                                                               .oo:ol.                             //
//      :XMMMMMMK,          ..                                                     ld'.                               //
//      cWMMMWNNl          ..                                                      c:      AQUEOUS                    //
//      :NMMMkc:.         ':,        ..'cdddol::;,'....                            ;d.     EDITIONS                   //
//      '0MMMx.         .lOx'          ;KMMMMMMMMWWNXK0kxo'                        ,xc                                //
//       lNMK;        .:kXNc          '0MMMMMMMWMMNOddOOkkxd,               ....  .,:d.                               //
//       .xWXx,      ;xXWMk.          dXOKKkKWMKkKK:       ';'.            ...',;.';.ol                               //
//        '0MX:    .dXWMMK;          .xko0k..kWXl;o;                       .;o:.,od: :x.                              //
//         :XMo   'OWMMMNc           ,0NNWO. .kWx;;.                       '0Kx,.oK; ,d,                              //
//          dWO. :KMMMWNx.           :NMWNK:  '0Nd;;.                      .:c:..kk. ,kc                              //
//          '0NOkNMMMMNO,            lWMMWWKc  'kXx;c,                    .. ..,oO;  cx'                              //
//           dMMMMWWWXkc.            dMWNXNXo   .lKOloc.                  .....';,  'dl                               //
//           lWMMXk0Nkc'            .xMWKkOOo.    'lxdc;'.                    .:, .,od                                //
//           lWMWxlXKl'.            .xWWN00Oloc     .ckkdl;. .:,           .,:;. .;lxc                                //
//           dMMKcdNx.               o0ldNMWdcOk;.    .:ccloool:,';c:,',::;;;.   'oox;                                //
//          .kMMxc0Xc                ;O, cXMKldNWk,         .';;;:cllc::;.       .;:d:                                //
//          ,KMNooNk'                ,O:  oWMXOKMMXo.                            .,'ol                                //
//          oWMXokNk;.               .x:  '0MMNXWKdxd,                           .,.ll                                //
//         .OMM0lkXk,                .d:   oMMWXNk..,lc.                         .,.:o                                //
//         :XM0c;kKl.                .o:   :NMWKXK,  .coc,                       .,.,c.                               //
//         dMX: ;K0,                 .o:   ,KMWOkNc    .',;.                      ''.;.                               //
//        '0MO. :Kd.                 .o:   ,KMWdc0c       ,c'                     .'.,'                               //
//        lWWo  l0l                  .do.  '0MXl,:.       .:c;.                    ,.,;                               //
//       .kMX; .ok'                   ld.  :XWK:.          .:c:.                   '.;:                               //
//       ,KMO. :kl                   .od. 'OMNk,            .;cc'                  ..c:                               //
//       lWWo 'k0,                    cl.;0WW0l.              .co'                 .:o.                               //
//      .OMO..lkx.                    ;0XNMWKO:                .''                 .dc                                //
//      :NMx'lllc                     ;XMMMXXO'                                    lx.                                //
//     .xMMOod;:,                     :NMMMWXo.                                   ;d'                                 //
//     ,KMWxdo.,'                     lWMMMWXk'                                  'kc                                  //
//     dWMNdkl.,.                    'OMMMMWNo                                  .cO:                                  //
//    ,KMMXkO:.,.                   .cXMMMMMX;         .;.                      ';xc                                  //
//    lWMM0O0;.'.                   .cKMMMMMO.         ,l,                     ';,x:                                  //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AQUEE is ERC1155Creator {
    constructor() ERC1155Creator() {}
}