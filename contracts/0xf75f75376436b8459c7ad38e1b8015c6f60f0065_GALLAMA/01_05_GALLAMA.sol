// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gallus Llama
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOlcOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOclkXWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWKx:.  ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;  .:xKWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWXkc.    .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk.    .:kXWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMW0l'       cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl       .l0WMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMNO:.        'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'        .:kNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNk;.          oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.         .;xNMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWO;            ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;            ;OWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWKc.            .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.            .c0WMMMMMMMMMMM    //
//    MMMMMMMMMMMMMNd.             :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc            .;OWMMMMMMMMMMM    //
//    MMMMMMMMWXKXWMWO,           .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO'          .xNMWNKKNWMMMMMM    //
//    MMMMMMM0c...lXMMO'          cNMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNXXNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMNc         .dWMNd'..;kWMMMMM    //
//    MMMMMMWd.   .kMMK,          .oXMMMMMMMMMMMMMMMMMMMMMMWKxl;,'...';lxKWMMMMMMMMMMMMMMMMMMMMMMXd.         .OMMK,    cNMMMMM    //
//    MMMMMMMXd;,:xNMWx.            ,kWMMMMMMMMMMMMMMMMMMWO:.            .:ONMMMMMMMMMMMMMMMMMMWO,           .lNMWOc;;lKMMMMMM    //
//    MMMMMMMMMWWWMMWk.              .dNMMMMMMMMMMMMMMMMXl.   .cdxkkxdc.   .cKMMMMMMMMMMMMMMMMNd.             '0MMMWWWMMWWMMMM    //
//    MMMMMWkldkk0NMWO'               .lXMMMMMMMMMMMMMMXc   .dXWMMMMMMWXd.   :XMMMMMMMMMMMMMMNo.             .xNMW0xkkdl:xNMMM    //
//    MMMMWk.    .lXMWO,                cXMMMMMMMMMMMMWx.  .xWMMMMMMMMMMWk.  .xWMMMMMMMMMMMMXl.             .xWMNd.      .xWMM    //
//    MMMM0,       lXMWO,                cXMMMMMMMMMMMWo   ,KMMMMMMMMMMMMX;   lNMMMMMMMMMMMXc              'kWMNd.        'OMM    //
//    MMMXc         lXMWO,                cXMMMMMMMMMMWx.  .kMMMMMMMMMMMMO'  .xWMMMMMMMMMMXl              'OWMNo.          :XM    //
//    MMWk.          cXMWO,                lXMMMMMMMMMMX:   ,kNMMMMMMMMWO,   ;KMMMMMMMMMMNl.             ,OWMXl.           .xW    //
//    MMX:            cXMM0,               .oNMMMMMMMMMMK:   .;ok0KK0Od;.   :KMMMMMMMMMMNo.             ;0MMXc              ;K    //
//    MMk.             cXMW0,               .oNMMMMMMMMMMXx,.    ....     ,xXMMMMMMMMMMNd.             :KMMK:               .x    //
//    MWl               cXMW0,               .dWMMMMMMMMMMMNOo:'.     ':lONMMMMMMMMMMMWx.             :KMWK:                 l    //
//    MK;                cXMW0:..             .xWMMMMMMMMMMMMMWXl    cXWMMMMMMMMMMMMMWk.          ...lXMW0;                  ,    //
//    MO.                 cXMMNKKOxc.          'OWMMMMMMMMMMMMMMd.  .dWMMMMMMMMMMMMMWO'       .;ok0KXNMM0,                   .    //
//    Mk.                .dNMWNXXWMWKl.         ,0MMMMMMMMMMMMMMx.  .xWMMMMMMMMMMMMM0;       'xNMWNXXWMMK:                   .    //
//    Mx.               .oNMNx,..;OWMXc          :KMMMMMMMMMMMMMO.  .kMMMMMMMMMMMMMX:       .kWMXo'..cKMMK,                       //
//    Wd.               'OMMK,    cNMWd.          cXMMMMMMMMMMMM0'  '0MMMMMMMMMMMMNl        ,KMMO.   .dWMNo.                      //
//    Mx.            .'ckNMMWk:',c0WMNl           .oNMMMMMMMMMMMK,  ,KMMMMMMMMMMMNo.        .kWMNx;',oKMMWXxc,.                   //
//    Mk.         ':d0NMMWXXWMWWWWMMMWO:.          .dWMMMMMMMMMMX:  ;XMMMMMMMMMMWx.        .c0WMMMWNWMMNKXWMMNKxl,.          .    //
//    MXxol;...;oOXWMWXko;..:dkOOkdd0WMNOc.         .kWMMMMMMMMMNc  :XMMMMMMMMMWk.       .:OWMW0xxOOkxl,..;lkXWMMNKxl,..,clold    //
//    MMMMMWX0XWMWNOd:.             .l0WMW0c.        'OMMMMMMMMMWl .lNMMMMMMMMM0,      .:ONMW0l.             .;lkKWMMNKKNMMMMM    //
//    KdllxXMMMXxc'.                  .cOWMW0l.       ;KMMMMMMMMWo..oNMMMMMMMMK;     .;kNMWKl.                   .;oOWMMNOocoO    //
//    :    cNMMx.                       .:ONMWKo.      :XMMMMMMMWx,,xWMMMMMMMXc     ;kNMWKl.                        :XMWk.   .    //
//    o.  .dNMWo                          .;kNMWKd'    .oNMMMMMMMk::kMMMMMMMWd.   ;kNMWKo.                          ,KMM0;. .,    //
//    WKkkKWMNk'                             ;xNMWXd,   .xWMMMMMMOllOMMMMMMWk.  ,kNMWKo.                             cKMMXOkOX    //
//    MMMMWKk:.                                ,dXWMNx;  'OWMMMMMKxd0MMMMMM0,.,xNMWKo.                                'oOXWMMM    //
//    MMMMNo.                                    'dKWMNk;.:KMMMMMN0OKMMMMMXl;xXMMXd'                                    .'xWMM    //
//    MMMMM0,                                      'oKWMNOlxNMMMMWNKXMMMMWKOXMMXd'                                       ,0MMM    //
//    MMMMMWO'                                       .l0WMWXNMMMMMWWWMMMMMWMMXd'                                        .kWMMM    //
//    MMMMMMWk'                                        .c0WMMMMMMMMMMMMMMMMXd'                                         .kWMMMM    //
//    MMMMMMMWO,                                         .cOWMMMWNXXNWMMMNx,                                          'kWMMMMM    //
//    MMMMMMMMW0,                                          :KMMKl'..'lXMMK,                                          ,OWMMMMMM    //
//    MMMMMMMMMMKc.                                    .,cd0WMWx.    .xMMW0dc,.                                    .cKMMMMMMMM    //
//    MMMMMMMMMMMNx.                              .,cdOKNWMWWMMXd;'';dXMMWWMWNKOo:,.                              .dNMMMMMMMMM    //
//    MMMMMMMMMMMMW0:.                       .,cdOKNMMWN0xl::xNMMWNNWMMNx::okKNWMWNKko:'.                        :0WMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNk,    ....         .':okKNWMWNKko:'.     'l0WMMW0l'     .':okKNWMWNKko:'.         ...     ,xNMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMXd:cx0KXKOd;..':okKNMMWNKko:'.            lNMMWl            .':okKNWMWNKko:'..;dOKXK0xc;dXMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWWMWXKXWMNKKNWMWNKko:'.                 lNMMWl                 .,:okKNMMWNKKWMWXKXWMWWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMM0:...lXMMWXkoc'.                      lNMMWl                      .,cdOXMMMKl...c0MMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWd.   .OMMK:                           lNMMWl                           cNMMk.   .xWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMXd;,:kNMWx.                           lNMMWl                           .kWMNx:,:xXMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWWWMMMWOc'                          lNMMWl                          .cOWMMMWWWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOo;.                     'xWMMWx'                     .;oOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdc,.             .:kXWMMMMWXk;.             .,cdOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxo:,...    .oNMWKxooxKWMNo.    ...,:lxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXK0kxdoxNMWO'    'OMMNxodxk0KXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO'    'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOc;;cOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GALLAMA is ERC721Creator {
    constructor() ERC721Creator("Gallus Llama", "GALLAMA") {}
}