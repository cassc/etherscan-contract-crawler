// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Static Motion NFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//               ..;ccccc;'.    ,ccccc:;::cccc;.         ':cc,           ,ccccc::::cccc;. .:cc'       .';:cc:;'.                  //
//              ,xKNNNNWWWXO:  .xWWNXXK0KXNNNW0,        ;O0kkk:         .xWWNXXK0KXNNNW0, cXNXl.   .;d0KXXNXXXKOd;.               //
//             ,ONWNx:;;coOk;   '::::x0OXOc;;;,.       'kKOxxOO:         '::::x0OXOc;;;,. c00Xo.  'xNNX0dlc:cokXXx.               //
//             :KXXXo.    ..         :0KXx.           'xKX0xkO0O;             c0KXd.      cKKKo. ,OXNKl.      .,,.                //
//             .dXXNN0xoc;..         cKKKd.          .dXK0l.;OKXO,            cK0Kd.      :KKKo..oXXKl.                           //
//              .,lxOKXWNXKk:.       cK0Kd.         .oKK0o. .l0KXkc'          cK0Kd.      cKKKo .dNN0:                            //
//                  ..,cxKXNKc       cKKXx.        .l00OOkkxdkOOO0Xd.         cKKXd.      c0KKo. cKNXx.                           //
//             .cdl,.   ,kKXNo.      cKKXd.       .c00kOOOOkkkOOkOXKl.        cKKXd.      c0O0l. .dKKKx:.    .;ol'                //
//             cKWWNKkkk0NNXk'       cXNNx.       :KNXk:.......,dKXXKl.       cXNNd.      c0KXo.  .cOXNX0kxdk0NWNd.               //
//             .,ldO0XXKKOx:.        :0XKo.      'kXKk'         'x0KKO,       :0KKo.      ;OKKl.    .:ok00KK0Oxo;.                //
//                 .......           .....       .....           ......       .....        ....         ......                    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//        .....          .....          ......         ................   ....         ......          ...          ....          //
//       ;OOxxd:.       ,dxxkOc.    .,lxO0KKKOxo;.    .lKK000OkkO00KKKO, ,OK0l.    .,lxO0KKKOxo;.     c00xl'       ,kKKl.         //
//       cOo:lx0o.     ,kxl:l0x.   ;kXWWKkddx0NWNOc.   :xxddO0OKKxdddxo. :0XXd.   ;kXWWKkddx0NWN0c.  .oKOkOOc.     cXNWx.         //
//       :kc;;:dx;    ,xx:,',xo. .lXWW0c.    .;kNWNd.       :O0Xk.       :0KKd. .lXWW0c.    .;kNWNx. .o0dloOKd'    cKXNx.         //
//       :Oo:;:cdk:. ,kOo:;,;xo. :XWNO'        .xNWXl       :0KXk.       ;0XKd. :KWNO'        .dNWXl .oXkdx0KKOc.  cXNNx.         //
//       c0kxxoxOOOocOK0kooooOo..oWWNc          :KNNx.      :00Kx.       ;0XXd. oWWNl          :KNNx..oNXKdlOXNXx'.cXNNd.         //
//       cXXKd':OKOxO0K0l.c0KXd. lNWNo.         lXNNd.      :0KXk.       :0XXd. lNWNo.         lXNNd..dNWX: .oKNXOdxOOKd.         //
//       cKKXx. ;00ooO0l. :KXXd. 'kNNKl.      .c0WW0;       :0KXk.       :00Ko. .kNNKl.      .:0WW0; .dNNXc   ,x0kdlld0d.         //
//       cKXXx.  ;OKKKl.  :KNWx.  'dXWNOo:,,;lONNNk,        :KNNk.       ;O0Kd.  'dXWN0o:,,;lOXNXO,  .dNNXc    .ckkold0d.         //
//       cXNWk.   ,od:.   :XWWk.   .;xKNWWWNWWNKkc.         :KWWk.       ;0NNx.   .;xKNWWWNWWNKkc.   .dNWXc      'd0KKXd.         //
//       .cll,.           .:cc,.      .,:clllc;.            .:lc,.       .:lc,       .,:llll:;.       ,ll:.       .;lll,          //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                        .',,,,.           .,,,.     .,,,,,,,,,,,,,,,,,,,'.       .',,,,,,,,,,,,,,,,,,,,,.                       //
//                     ,loONWWNO:......  .;oON0o;.    :OOKNWWWWWWWWWWWWWWWXd'.   .'lKWWWWWWWWWWWWWWWWWWNKOl.                      //
//                    .cONMMMMMKo:,.......l0WMOc:,.   :x0XNNWWWNNWWWWWNNNNNx:,. .lKXNWWWWWWMMMMWNNNNNNWKc.                        //
//                    .ckNMMMMMMW0:. ..cxdokNWOol:.     .,,,,,,,,,,,,,,,,,,,''.  .,;::::::lk0KN0dddooc;'.                         //
//                    .lkXMMMXOKMXdc;..:dddkNWOc'          .........                .......dKXW0;':cc;.                           //
//                      .kMMMk';0WMMNd.    'OMMWd.           ..''''''''''...              .kWMMO'.',,,.                           //
//                      .kMMMk. 'OWMMWx.   'OMMWd.      .;dOOOOOOOOOOOOOOOOOkc.           .'oXMNOx;                               //
//                     'oKMMNk:'.,kNMMNx'.'oXMWNx,     .,lKMMMMMMMMMMMMMMMMWXk;            'xNMWOl'                               //
//                     cXMMWd... 'xNMMWk,.lNMMNl..       .dWMMNOoooooooooooool,            cXMMNl.                                //
//                    .lNMMWx'.   :KMMMNo'dNMW0,       ...;ONNXd.   .......               .c0WMXl,.                               //
//                    ,OXNMMW0;   .dXXNW0kXMMNo..     ;kOOOl,,,.    .......               .l0NMKl;'                               //
//                    ..'dWMMX; ....'.,xNWMMMWNKO;    ,x0KXx;''''''''..                    .lKMMWNd.                              //
//                     .,dNWKk, ......'c0WMMMMXOx,     :kOXXd;;'......                    .l0XWMMK;                               //
//                     .':k0kd,      .,lOKKXKO:.       ...cOOkd,                           ..;kKK0c.                              //
//                        ....          ......             ....                               .....                               //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SMNFT is ERC721Creator {
    constructor() ERC721Creator("Static Motion NFT", "SMNFT") {}
}