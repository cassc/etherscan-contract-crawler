// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MEME NINJAS
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//           .:xkkkxxxxdddolcc:::::;;;;;;;:::::cclodddxxxxxxxd,        .cxkkkxxxxdddolcc::::;;;;;;;;:::::cclodddxxxxxxxd'         //
//        'cdONMNKXMMMMMMMMMMMMMMMMMMMMMMMMWXXWMMMMMMMMMMMMMWXc     'cdONMNKNMMMMMMMMMMMMMMMMMMMMMMMMWXNWMMMMMMMMMMMMMWX:         //
//       .xWMMMMd.,OWMMMMMMX0XMMMMMMMMMMMMMO,.:xXMMMNOo:l0MMWXc    'OWMMMWl.;0MMMMMMWX0XMMMMMMMMMMMMMk''ckNMMMXkl:oKMMWX:         //
//       .kMMMMMx. .dNMW0o;..:KMMMMMMMMMMMMNx;. .coc'    lNMWO'    'OWMMMWo  .kWMNOo;..cXMMMMMMMMMMMMXd,  'ldc.   .dWMNx'         //
//       .xMMMMMN:   ,:'  .cxKMMMMMMMMMMMMMMMWO'      .lONMMX:     .OWMMMMK,  .;:'  'ckXMMMMMMMMMMMMMMMNx.      .l0WMMK,          //
//        cXMMMXO;      ,ONMMMMMMMMMMMMMMMMMNkc.      'OWMMMX;      lNMMMXk'      :ONMMMMMMMMMMMMMMMMMXx:.      ;OWMMM0'          //
//        .oNMK;   .;;. 'kWMMMMMMXdlOWMMMMXo'   .;oxo;. ;0MMX;      .xWMO'   .;;. ,0MMMMMMWKol0WMMMMKl.   .:dxo, .cKMM0'          //
//         .kMNd;okXMMK: .xWMMMMWo  .dNMMMKl;lxOXMMMMW0l:OMMX;       .OMXo:oONMM0; .OMMMMMNl  .xNMMM0c:oxONMMMMNOc:0MM0'          //
//          oMMMMMMMMMMWkdKMMMMW0,    :0MMMMMMMMMMMMMMMMMMMMX;        dMMMMMMMMMMNxdXMMMMWO'   .cKMMMMMMMMMMMMMMMMMMMM0'          //
//          oMMMMMMMMMMMMMMMMMMNc     .xXWWWMMMMMMMMMMMMMWWO;.        oMMMMMMMMMMMMMMMMMMX:     'kNWWMMMMMMMMMMMMMMWWk,           //
//          .ckXXK0XMMMMWXOxocld,      ..',:xkxddxkOK0kdoc,.          .ckXX00XMMMMWKkdoclo'      ..',cxkxddxk0K0xdo:,.            //
//            .... 'codxl.                          ..                  .... 'lodxc.                          .                   //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//             .,,,,''....                        .....''',,,'.         .',,,,''....                        .....'',,,,'.         //
//          .;xXWMWWWNNXXK0kxxxxxxxxxxxxxxxxxxxxxk0KXXNNWWWWWX:       .;kNWMWWWNNXXKOkxxxxxxxxxxxxxxxxxxxxxk0KXXNNWWWWWK;         //
//        :kKNWMKdOWMMMMMMMMMMMMMMMMMMMMMMMXxxKWMMMMMMNXNMMMWN:    .lOKNWW0o0WMMMMMMMMMMMMMMMMMMMMMMMKxkXMMMMMMMNXNMMMWX;         //
//       .xMMMMMo .lXMMMMN0dldXMMMMMMMMMMMMO' .:xXWXkc'.'dNMWX:    '0MMMMWc .dNMMMMN0dlxXMMMMMMMMMMMMk. .ckNWKx:'.'kWMWK;         //
//       .xMMMMMO.  ;OKkl'. .cKMMMMMMMMMMMMMXd,  .'.    ,xNMNo.    '0MMMMMk.  :0Kkc'  'lKMMMMMMMMMMMMWKd'  .'.   .;kWMXl.         //
//        dWMMMMWl   ..  ,lkNMMMMMMMMMMMMMMMMWO'      ,ONMMMX;     .kMMMMMN:   .. .,oONMMMMMMMMMMMMMMMMWk.      ;0WMMM0'          //
//        ,0WMNkc.      :XMMMMMMMWXKWMMMMMMXk:.   .'. .c0WMMX;      :KWMXx:.      lNMMMMMMMWKKWMMMMMWXx:.   .'. .lKMMM0'          //
//         ;KM0' .'cxx:. cXMMMMMMO'.cKWMMMK;  .,cxKWKd;..kMMX;       cXMO. .,lxx; .oNMMMMMWk..oXMMMMO' ..,lkXWKo, .OMM0'          //
//          oMM0x0WMMMWk'.kWMMMMWc   ,kNMMNOk0XWMMMMMMW0kXMMX;       .xMWOkKWMMMNd.'OMMMMMX:   ;OWMMXOk0XWMMMMMMNOkXMM0'          //
//          lWWWWWWWWWWWXKWWWWWNd.    'OWWWWWWWWWWWWWWWWWWWNx.        oWWWWWWWWWWWKKWWWWWNo.    '0WWWWWWWWWWWWWWWWWWWXd.          //
//          :KNMMMMMMMMMMMMWNXXX:     .cxxk0WMWWWWWMMMWWNKkc.         cXWMMMMMMMMMMMMWNXXK;     .lxkkKWWWWWWMMMMWWNKk:            //
//           .;ddllkXNWWXd:,'..,.          .;;,,,,:cll;,'.             .:dollkXNWWKd:,'..,.          .;;,,,,:llc;,'.              //
//                  .'';'                                                     .',;.                                               //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//            'ldddoolcc::,'''''''........'''''''',::ccllooooo.         ,ldddoolcc::,''''''''.......''''''',;::ccllooool.         //
//        .,:xKWMWWMMMMMMMWWNNNNNNNNNNNNNNNNNNNNNWWMMMMMMMMMWX:     .;cxXWWWWMMMMMMMWWNNNNNNNNNNNNNNNNNNNNNWWMMMMMMMMMWK;         //
//       .dWMMMMk,cKMMMMMMMWWWMMMMMMMMMMMMMO:;oKWMMMMKkxkXMMWN:    .OWMMMWd,lXMMMMMMMWWMMMMMMMMMMMMMMO;:dXMMMMWKkxkNMMWX;         //
//       .xMMMMMd  'OWMMXkl,':0MMMMMMMMMMMMKl. .:dkd:.   lNMWK;    '0MMMMWl  ,0MMMXkl,'cKMMMMMMMMMMMMKc. .cxko;.   oWMW0,         //
//       .xMMMMMX;  .ldc. .,lONMMMMMMMMMMMMMMXd.      .;oKMMNc     '0MMMMM0'  .od:. .,oONMMMMMMMMMMMMMMKo.      .;dKMMK:          //
//        lNMMMMX:      'o0WMMMMMMMMMMMMMMMMWKo.      ,0MMMMX;     .dWMMMWK,      ,dKWMMMMMMMMMMMMMMMMW0l.      :KMMMM0'          //
//        .xWMKc.   .'  ,0MMMMMMMNkdKWMMMMNk:.   .coc. .lXMMX;      'OWM0:.   '.  :KMMMMMMMNxdKWMMMMXx;.   'co:. .oXMM0'          //
//         .OMXc.:oONNk' .OWMMMMWd. .kWMMMKc,;cdONMMMXd;,kMMX;       ,0MK:':d0NNx. '0MMMMMNo  ,OWMMMO:,;cd0NMMWKo;;OMM0'          //
//          oMMNNMMMMMMXoc0WMMMWK;   .lKMMMMMMMMMMMMMMMWWMMMX;        dMMNNMMMMMMKllKMMMMW0,   .oXMMMMMMMMMMMMMMMWWMMM0'          //
//          oMMMMMMMMMMMMMMMMMMNl     'OWMMMMMMMMMMMMMMMMMMKc.        oMMMMMMMMMMMMMMMMMMN:     '0MMMMMMMMMMMMMMMMMMM0:.          //
//          'd0NWNNWMMMMMWXOxdxk;      ',;:d0K0OOOKXNX0Oxoc.          ,d0WNNNWMMMMMNKOxdxx'     .';:cd0KOOOOKXNX0Oxoc.            //
//            .,'..:dxO0x;.                 ...   .....                 .,'..:dkO0d,.                 ..    .....                 //
//                     .                                                         .                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NINJAS is ERC1155Creator {
    constructor() ERC1155Creator() {}
}