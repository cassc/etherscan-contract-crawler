// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: compusophy1155
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                 ..  ..  ..                                                 //
//                                       .. ... .'... .::. ..... ... ..                                       //
//                                 .. ..... ';.  .,.  .cc.  .,.  .;. ...'. .                                  //
//                              ...'.  ',     ,d:     ;xx;     :d'     ,'  .....                              //
//                           .. . .,. .cl.    .;.     '::.     ';.    .lc. .,.   ..                           //
//                        ....;'       ,;..;:.       ,0WW0'       .:,..;,       '; ...                        //
//                      ..'.   .oo.       cNWk.      .:oo:.      .OMX:       .ol.   ....                      //
//                   ..  .,.    .,.       .:c'        .''.        'c;.       .,.    .,.  ..                   //
//                 ...;' .c;    :OO:                'xXNNKd.                cOO:    ;c. ';...                 //
//                 .. .. .c;    :Ok:   '::,         cNMMMWX;        .,::.   cOO:    ;c. .. ..                 //
//               .',.                 lXWWNd.       .:xkkx;.       .xNWWXc                 .,'.               //
//             .. .':o'  ..          .oWMMWk.                      .OWMMNl           ..  ,o:'  ..             //
//           ...,.  'c..xXO,          .;oo:.         .''''.         .col;.          ;0Xd..:.  .,...           //
//           ...'.     .lko.                       ,xKNNNX0d'                       'dxc.     .'...           //
//          ... .,.        .,cl;.                 ,KMWMMWWWNO'                 .;lc,         .,. ...          //
//         . ''.:d'       .dNMWNx.     .;::;.     :XMMMMMMWNK;     .;c:;.     .xWMWNo        'x:.''..         //
//        ..       ..     .oNMMNd.   .dXWWWNKo.   .oXWMWWWNKl.   .dXWWWNKo.   .xWMWXl.     ..       .         //
//       ..',.   .lXXl     .,cc,.   .xWMMMMWWNo.    'coooo:.    .xWMMMMWWNo.   .;cc,      lXXl    .,'..       //
//       ....;o'  ,dd,              .xWMMMMWNNo.                .xWMMMMWWNo.              ,dd,  ,o;.. .       //
//      .... 'c.                     .xXWMWNKo.                  .dXWWWN0o.                     'c' ....      //
//      ..''                           .;c:;.       ..'''...       .;::;.                           ''..      //
//      .             .col;.                     .;dOKXXXX0ko;.                     .;loc.             .      //
//     ..''.lo..co:. .OWMWNo.    ,lodo:.        ,kNWWWWWWWNNNXx'        'codoc'    .oWMMWk. .:o:..ol.''..     //
//     .....'' ,KWO' .xNMWKc   .dNWMWWNKl.     '0WMMMMMMMMWWWNXk.     .lXWWWWWXo.   lXWWNd. '0W0, ,'.....     //
//     ...      .,.   .,:;.    :NMMMMMWW0,     cNMMMMMMMMMMWWNNK;     ;KMMMMMWWK;    '::'    .,.      ...     //
//     ..''                    ,KMMMMWWNk.     ;XMMMMMMMMMMWWNN0,     'OWMMMMWNO'                    ''..     //
//     ..  .oo.                 ,xKNNXOo.      .oNMMMMMMMMWWNXKl       'd0XNX0o'                 .ol.  ..     //
//     ...'.''                    ..'..          :ONWWWWWWNNKx,          ..'..                    ''.'...     //
//      ..'.    ,k0o.    ','.            ..        'codddol:'        ..            .',.    .o0x,    .'..      //
//      ..    . ,kOl.  .xNWNO,        'okOOkl'                    ,okOOxl'        ;ONWXx.  .oOx' .    ..      //
//       .',.;x,       ;XWMMXc       cXMMWWWNK:                  cXMWWWWNK:       lWMMWK,       ;x;.,...      //
//       ..  ..         ,odo;.      .kWMMMMWWNx.     ......     .kMMMMMWWNx.      .:ddo,        ...  ..       //
//        ...'                       cXWMMWWW0:    'o0XXXKOo.    cXMMMMWN0:                       '...        //
//         .''  .,. .co:.             ,ok0Oxl'    '0WMMMWWWNO'    'ok0Oxl'             .:oc. .,.  ''.         //
//         ..  .cd' ,KWO'        .''.    ..       :XMMMMMMWNK;       ..    .''.        '0W0' 'dc.  ..         //
//          ..''.    .'.        c0NN0c.           .dNMMWWWWKl.           .lKNN0:        .'.    .,'..          //
//            .                .kMMWWk.             ,ldddoc'             .OMMWWx.                .            //
//            .. ,' ;x,     .'. 'okxo'                                    'okxl. .'.     ;x; '' ..            //
//              ..  ...    'ON0,             .lxxl'          'oxxc.             ,0Nk'    ...  ..              //
//                ...'    .'cdc.            .xWMWWO.        '0MWWWd.            .co:..    ,...                //
//                ....   'dc          ..     cKNNKl.        .oXNN0:     ..          cd'   ....                //
//                  .. .;'..        .l00:     .''.            .''.     cO0c         ..';. ..                  //
//                     ..   .. .cl.  :kx;       .;,         .,;.       ;kk:  .cc. ..   ..                     //
//                       ...;'  ;;.    .       .kWNc        cNWx.       .    .;,  '; ..                       //
//                          ..  ''    .lo.     .,l:.        .cl,      .dl.    ''  ..                          //
//                             ....  ,'..     'x:     'cc'     :x'     ..',  ....                             //
//                                ...'.  .,.  .l,     ,ol'     ;l.  .'.  .'...                                //
//                                      ..... .:.   ''    ''   .:. .. ..                                      //
//                                            .. ... ..  .. ... ..                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract c1155 is ERC1155Creator {
    constructor() ERC1155Creator("compusophy1155", "c1155") {}
}