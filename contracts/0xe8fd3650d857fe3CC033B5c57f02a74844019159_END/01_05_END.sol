// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ENDGAME
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                    ......                                  //
//                                                                   ;OXXKK0x'                                //
//                                                                  :KMMMMMXl                                 //
//            .''''''''''''''''''''''''''''''''''''''''''.        .lXMMMMMWO:,,,,,,,,,,,,,,,,,,,,.            //
//           ;KNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNk.      'xNMMMMMMMWWWWWWWWWWWWWWWWWWWWWWO.           //
//           :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.    .cKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.           //
//           :XMMMMN0OOOOOOO00000OOOOOOOOO000000OOOOOOOOOo.   ,kNMMMMMMWWWWWWWWWWWWWWWWWWMMMMMMMMO.           //
//           :XMMMMk.      :kOOOx,       .lOOOOo.           'xNMMMMMWKl;;;;;;;;;;;;;;;;ckNMMMMMMXl.           //
//           :XMMMMx..,;;;;xWMMMNd;;;;;;;c0MMMMKc;;;;;,. .,dXMMMMMMXd. .,.            ,xNMMMMMWO;             //
//           :XMMMMx.lNWWWWWMMMMMWWWWWWWWWMMMMMMWWWWWWNkcxXMMMMMMNk, .lKN0o'       .;kNMMMMMW0c.              //
//           :XMMMMx.lNWWWWWMMMMMWWMWWWWWWMMMMMMWWWWWWNd,:kWMMMNk;  :0WMMMMXx:.  .lONMMMMMWKl.                //
//           :XMMMMx..,;;;;xWMMMNdxXXOdc;c0MMMMKl;;;;;,.  .oXXx;    :ONMMMMMMW0dxXWMMMMMW0l.                  //
//           :XMMMMx.      .clllldKMMWXd. ,llll;            .'       .;xXMMMMMMMMMMMMMNk:.                    //
//           :XMMMMx';cc:cccccccxNMMMMWOlcccccccccccccc,..             .dNMMMMMMMMMW0o'                       //
//           :XMMMMkc0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0l'         .;lxKNMMMMMMMN0d;.                         //
//           :XMMMMkcOWWWWWWMMMMMMMWWWWWWWWWWWWWWWWWNNWOl.   ..,cdOXWMMMMMMMMMWXxc,,,,,,,,,,,,,,,'.           //
//           :XMMMMk..,,,cONMMMMMXo;''''''''''''','''',;::cox0XWMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWX:           //
//           :XMMMMk.  'l0WMMMMMNkc::::::::::::::::;.  ,d0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc           //
//           :XMMMMO:ckXMMMMMMMMMMMMMMMMMMMMMMMMMMMK,   .cXMMMMMMMMMMMMMWMMWWMMMMMMMMMMWWMMMMMMMMNc           //
//           :XMMMMWWWMMMMMMMMMMWNNNNNNNNNNNNNWMMMMK,     oXX0xxXMMMMMOc;;;;;:;;;;;;;;:;;;:xNMMMMNc           //
//           :XMMMMXKWMMN00WMMMNo'''''''''''''dNMMMK,     .'.  '0MMMMWo                    :XMMMMNc           //
//           :XMMMMk;dOd,.:XMMMNd;;;;;;;;;;;;:xWMMMK,          '0MMMMWo                    :XMMMMNc           //
//           :XMMMMx.     :XMMMMMWWWWWWWWWWWWWMMMMMK,          '0MMMMWo                    :XMMMMNc           //
//           :XMMMMx.     ;KWWWWWWWWWWWWWWWWWWWWWWW0,          '0MMMMWx'...................oNMMMMNc           //
//           :XMMMMx.     .',,,,,,,,,,,,,,,,,,,,,,,'           '0MMMMMWXXXXXXXXXXXXXXXXXXXXNMMMMMNc           //
//           :XMMMM0c;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;'.    '0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc           //
//           :XMMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW0,    '0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:           //
//           :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,    '0MMMMM0olcclcclcccccccllcllkWMMMMNc           //
//           'dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo.    .oOOOOk:                    'dxxxxd'           //
//            .........      ....        .     ..    ..            ....                    .    ..            //
//           ,xOOO0OOOOc  .cx0000kl.   .dOc  .oOx, .lOd.    .o0l. .l00O:     :O00c   cO0OOOk:  ,kk,           //
//           .,,:OMXl,,..:KNOc,;cOWK:  '0Wd.,ONO,  .xMO.    .OMk. .kWNWK;   ,0NWMx. .xMKl,,,.  :NNc           //
//              .dM0'   ,KWk.    .OM0' '0WkdKXl.   .xMO.    .OMk. .kWOONk. .kXk0Mx. .xMKl,,'.  :NNc           //
//              .dM0'   :NWo     .dMK; '0WKKW0,    .xMO.    .OMk. .kWd;ONo.oXd;OMx. .xMN0OOx'  :NNc           //
//              .dM0'   '0M0,    ;0Wk. '0Wx;kNKc.  .dWK;    ,KWd. .kWd.;XXOXO'.OMx. .xM0; .    :XNc           //
//              .dM0'    ,ONKxooxXNx'  '0Wd .lXNx'  'OWKkdld0NO,  .kMd. lNMK: .OMx. .xMXxlll;. :XNc           //
//               ;oc.     .,ldxxoc'    .co,   ,oo:.  .:oddxdo:.    ;o,  .:o;  .:o;   ;oooooo:. .ll.           //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                    xn--ikrqs.net           //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract END is ERC1155Creator {
    constructor() ERC1155Creator("ENDGAME", "END") {}
}