// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Extinction Rebellion
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//               .;:.                         .;'.        ..                 .;;.                        .';..       ...               //
//               'ONx'      .,;'.            .oXXkc.  .'cxOx;.               ;KXo.      .;;'.            .xNKd;.  .,lkOd,              //
//               .xWWO;. .;d0NNk'             .cONW0dokXWMMNo.               'OMNx' ..:x0NXd.            .'o0WNOooONWMWKc.             //
//                :KMMKxx0NN0d:.                .cKMMMMMWKo,.                .lNMW0dxKWNOo;.                .oXMMMMMWOl'.              //
//               .cKMMMMMNx;.                  .;xXMMMMMWk'.                 .oNMMMMMXo,.                  .:kNMMMMMNd.                //
//             .cONMMNKXWNo.                 .cONMMN0dlxXWKl.              .oKWMWXKXWXc.                .'o0WMWNOolkNW0:.              //
//             .cKKxl,.'oXNx'               .cKKOdl,.  .'l00:.             .oX0dc'.,xNXo.               .oKKkdc,.  .,d0O,              //
//              ....    .;kk,                ....         ...               .'.     .cOd.                ....        ....              //
//                        ..                                                         ...                                               //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                           .,ol,.     ..,'.                 .;dc.                         'lo;.      .,,.               .cd;.        //
//    .    .,ldl'.           .:0WXk:...:xKNXd.                .oWNd.     .'cdo;.            ,kNNOl'..;d0NNk,              .xWXc.       //
//    d'.;oONWKd,              .lOWWKOKWMMN0l.                 ;KMWkc,.,lkXWXk;.             .:kNWXOKNMMWKd'              .cNMNd'.,    //
//    WKKNNKd:..                 ,OWMMMMWO:.                   .dWMWWX0XWXxc'.                 .xWMMMMMKl..                'OMMWKKN    //
//    MMMNd.                  .'o0WMMWNWWKl.                 .'c0WMMMMMWk,.                  .cONMMWNNMXd'.              .,oKMMMMMW    //
//    dxKW0:.                'xXWWN0d:,:xXW0:.               ;0WMN0xdd0WXl.                .oKWMNKxc,;oKWKc.            .cXMWNOxxKW    //
//      ,kNK:.               ,dxo:,.    .'lx:.               .lxl;.   .oXNl.               'oxoc;..    .cxl.             'dxc,.  ,x    //
//       .cl'                                                 ..       .:o;.                                              .       .    //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                ...                         ...                            ...                          ...                          //
//               .x0c.       ...             .l0kc..   .'coc.                ;OO;.       ...             .d0x:.    .,co:.              //
//               .kMNd.   .;oO0x'            .;xXWKd:,ckXWMWd.               ,0MKl.  ..:dO0o.            .:ONW0o;;lONMMNl.             //
//               .cNMWk::d0NN0d;.              .,dXMWNWMMN0o'.               .dWMNx;cxKWNOo,.              .:kNWWWMMMNkc.              //
//                ,0MMMWWW0d;.                  .cKMMMMMWx'                  .cXMMMWWNOl,.                  .oXMMMMMNo.                //
//             .,o0WMMWWMXl.                 .'l0WMMN0OKWNx,.              .;dKWMMWWMK;                  .,dKWMMN0OXWKo'               //
//             .oNWXkl:cOWXc.               .cKWNKko;...cONK:.             .kWWKxl:l0W0;.               .oXWN0xl,..'o0NO,              //
//              .::'.   .oX0;                'c:,..      .;c'               'c;..   'xXk'               .,c;'..      .::.              //
//                       .,,.                                                        .,'.                                              //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                            .;,.        ..                   ':'                          .,,.        ..                .,:.         //
//          .';,.            .cXNOc..  .cxOk:.                .oN0:.      .';;.             ;0N0o'.  .:dOOl.              .kWO,        //
//    :. .;oOXNO;.            .:kNWKxoxKWMMNx.                 :XMXl'. .,lkXNKc.            .;xXWXkod0WMMWO,              .oNW0:. .    //
//    XxdONNKx:..               .:0WMMMMWKd;.                  .kWMNKkdOXWXkc'.               .,kWMMMMMNk:.                ,0MMXxdO    //
//    MMMNk:..                 .,dXMMMMMWO;.                  .'kWMMMMMW0c'.                 .'l0WMMMMMKc.                .;0MMMMMW    //
//    KKWWx.                 .ckXMMWKxldKWXd'                ,xXWMWX0KNWO,                 .;xKWMWKklo0NNx,.            .;ONWMNKKWW    //
//    ..cKWk,                :0KOxl;.   .cOKl.               ,kXOo;...:ON0:.               ,kK0ko:..  .:kKd.            .:0Kkl,..lK    //
//       ,xk;.               ....         ...                 ...      .dOc.               ....         ...              ....    .,    //
//        ..                                                            ...                                                            //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//               .ld,                        .;oc'.     ..,'.                'oo.                        .co:.      .',..              //
//               'OW0:.    .;ldl.            .cKWXx;..'ckXNXl.               ;KWk,     .:od:.            .dXWKo,..,lOXN0:.             //
//               .oWMXl..;d0NN0o'             .'o0WNKOXWMMNOc.               .xWW0:..:xKNNOl.             .,dXWN00XWMMXk;.             //
//                ,0MMWKKNN0d;.                 .:0MMMMMWk;.                  cXMMNKKWNOo,.                 .lXMMMMMNd,.               //
//              .;dXMMMMMXl.                  .,oKWMMWNWW0c.                .:kNMMMMMK:.                  .;xXMMMNNWNk;.               //
//             .oNMWXOdxXWO,                .;kXWWXOd;,:kXNk,              .xWMWKkdONNx.                .:ONMWXOo,,lONNd.              //
//              ,xxc'. .;OW0,               .;xdl:'.    .,ox;.             .:xd:.. .c0Nk'               .cxdl;'.    .;dd'              //
//               .       .ll.                                                .       ,lc.                                              //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract XREBEL is ERC721Creator {
    constructor() ERC721Creator("Extinction Rebellion", "XREBEL") {}
}