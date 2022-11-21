// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NOOD in AI
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                            //
//                                                                                                                                            //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    //                                                                                                                                //    //
//    //                                                                                                                                //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0kdlc:;,,;;;;;;::clodk0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo:'.                      ..;cox0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l'                                 ..,cdOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:.                                         .:oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:.                                               'ckXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.                                                    'lONMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,                                                         ,dXWMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk.                                                            .oKWMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO.                                                               .dXMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;                                                                  ;OWMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.                                                                   .dNMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.                                                                    .oNMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                                                                     .oNMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                                                                      .xWMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                                                                       ,0MMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNl.  ,ol:,'.........'',;;;:::ccclloooddoooolc:;'..                         lNMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMNo. .lXMMWWNXXXKKKXXNNNWWWMMMMMMMMMMMMMMMMMMMMMWXx:,,,'.                    .OMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMNo. .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;  ........                lNMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMNo. .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.       ...               ,0MMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMWd.  lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.                         .xMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMWk.  ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                           oWMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMM0,  .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                           cNMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMNl   cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:                            :XMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO'  .xMMMMMMMMNOxOXWMMMMMMMMMMMMMWKxddx0WMMMMMMMMMMMMx.                            :XMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMWo   '0MMMMMMMMk.  .lKMMMMMMMMMMMKc.    :XMMMMMMMMMMMNl                             cNMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMN:   :XMMMMMMMMNx:...xWMMMMMMMMMMO,..;okKWMMMMMMMMMMMNc                             cNMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMNc   cNMMMMMMMMMMWXKXWMMMMMMMMMMMWNXKKXXWMMMMMMMMMMMMWd.                            lWMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMWx.  :NMMMMMMMXxc;:dKWMMMMMMMMMMMMKo,...,oKMMMMMMMMMMMXc                 ..',;;;.  .dWMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMWOo':XMMMMMM0,     ,OMMMMMMMMMMM0,       ,0MMMMMMMMMMMNd'         ..;colclooddo'  .kMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMWd;OMMMMMK;       :XMMMMMMMMMNc         :XMMMMMMMMMMMWNOolccloxOKNXkddxOKXNXKOd,.dWMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMM0;dWMMMMk.       '0MMMMMMMMMK;         .OMMMMMMMMMMMMMMMMMMMMMMMWOxKWWKkxddk0WNx:dNMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMNl:KMMMMk.       ,KMMMMMMMMMX:         .OMMMMMMMMMMMMMMMMMMMMMMMWWMMNOxOOclkooKWx;kMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMM0:dWMMM0,      .oWMMMMMMMMMWx.        ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMXdOMXloW0;oWMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMWd;kMMWXo.    .dNMMMMMMMMMMMNd.      .oXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX0NWOckWO;xMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMNOollOWMMMW0l,:xKWMMMMMMMMMMMMMW0o;...cONMMMMMMMMMMMMMMMMMMMMMMWXXMMXO0WMWWXdlkWKccXMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMWKdcokKWMMMMMMMWX0NMMMMMWXNMMMWMMMMMMXOOKWMMMMMMWNKXWMMMMMMMMMMMMMM0d0WWKxxxxdoxXNk,;0MMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMKocdKWMMMMMMMMMMMMMMMMMMMNkx000XMMMMMMMMMMMMMMMWXOOKWMMMMMMMMMMMMMMMW0dx0NWX00KK0d;. :XMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMWk:lKMMMMMMMMMMMMMMMMMMMMMMMN0O0XMMMMMMMMMMMMMMMXkkKWMMMMMMMMMMMMMMMMMMMN0kxxxxdd:.    :XMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMWx;dNMMMMMMMMMMMMMMMMMMMMMMNX0OkkkO0KXNWMMMMMMMW0dONMMMMMMMMMMMMMMMMMMMMMMMMMNXXXN0,    ,KMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMO;oNMMMMMMMMMMMMMMMMMMMWKxc,..      ..':d0WMMMWko0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.   .OMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMNl:KMMMMMMMMMMMMMMMMMMMNd.    .';:::,'.   .:d0NkoKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:   .dWMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMX:cNMMMMMMMMMMMMMMMMMMNl   .:kKKOkkkOK0x;.   .clOMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo    ,KMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMX:cNMMMMMMMMMMMMMMMMMMO.   lNWk;'',;';OMNl     lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo     oNMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMWo;0MMMMMMMMMMMMMMMMMMk. .,oKWkd00K0ooKMXc    .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:     .xWMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMM0:oNMMMMMMMMMMMMMMMMMXl'lK0kxxKWNOxO0Okxl.   .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.      .xWMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMWk;dNMMMMMMMMMMMMMMMMMWNWMMWX00K0kkOO0XWNd;;,,xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;        .oNMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMWO:lKMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMMMMMMWWXclNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:           :0WMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMKo:dXMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMk:xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0;             .lKWMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMW0l;o0NMMMMMMMMMMMMXOXMMMMMMMMMMMMMMMMMMMNd:kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd'                :XMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMW0lcooodOXWMMMMMMMMWOokNMMMMMMMMMMMMMMMMMMNd,oXMMMMMMMMMMMMMMMMMMMMMMMMMXxclxo.            'o0WMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMXdcxNMWKkdooddkO0KXNNNOcl0WMMMMMMMMMMMMMMWXkddlcxXWMMMMMMMMMMMMMMMMMMMNOoclOWMMKo.          :KMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMWkcoKMMMMMMMWX0kxdddddxxxxoodONMMMMMMMMWXOkxdONMW0olox0NWMMMMMMMMMMWX0xollxXWMMMMMW0c.    .,:lkNMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMXo:kWMMMMMMMMMMMMMMMMMWWWMMMN0xxxkkkkkkxxxkk0WMMMMMMNOdooooddxxxxdooooodOXWMMMMMMMMMMWk, .,kNMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMXl:0WMMMMMMMMMMMMMMMMMMMMMMMMMMMWXK0OOO0KNWMMMMMMMMMMMMMMNK0kxxxxxkO0XWMMMMMMMMMMMMMMMMMXl;kWMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMXlcKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd:kWMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMWo:0MMMMMMMMMMMMMMMMMMMMMMN0XMMMMMMMMMMMMMMMMMMMMMMMMMMMWKONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx:xWMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMK:oWMMMMMMMMMMMMMMMMMMMMMMOdXMMMMMMMMMMMMMMMMMMMMMMMMMMMMKlxWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo;0MMMMMMMMM    //    //
//    //                                                                                                                                //    //
//    //                                                                                                                                //    //
//    //                                                                                                                                //    //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//                                                                                                                                            //
//                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NOODAIE is ERC721Creator {
    constructor() ERC721Creator("NOOD in AI", "NOODAIE") {}
}