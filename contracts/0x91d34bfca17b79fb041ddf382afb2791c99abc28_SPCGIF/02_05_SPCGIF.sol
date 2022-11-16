// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SpacePunksClub Animated GIFs
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKkdlcc::::cldk0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xl:'..           ..';lxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkc'.                       .;o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl.                              .;xXMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk;.                  ...''''','....   ,xNMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk;            .....'''''''''..',,;;:::;,'.c0WMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:          ..',,'...................'...',;;ckNMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWx.       ..',,'...  .....'',;::::::;;,'.......;lkNMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNd.      .':c'.  ..,:ldkkOOO0KXXNNNNNNXKOxoc;'..'cx0WMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMNd.     .;:,',,',cxO0000KXNWMMMMMMMMMMMMMMMMWNOo,...dNMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMk.    .,:,.  .;x00kocok0NWWMMMMMMMMMMMMMMMMMMMMMXx' 'OWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNkl;..  .::.  .:kKkc..;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:.:ldNMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWx.  .',,:;.  ,kXk,  'xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd;'oNMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk..''',c;   cKKc   ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,cNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMXc''. ,;.  cXK;   .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;oWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWo',.,l,  ,0Nl    ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,lNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMx':,.,'  lW0'    ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO'cNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMXd;:;.   .xMXc    lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.lWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWo.:cc.   .xMMNkookNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWl.dMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNl ,c:;.   lWMKdccdXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,.OMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWd.'o,...  ,KWx.  'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx..OMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMK;,l. .'. .oWWKOOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWK, ,KMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMM0l:'.',,. .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0KXl .xWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNOoc;,;,,:;,. .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0dOXo..oNMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNx,   ;o;;llc;,,..lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKdlOXo..dNMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNo.   ;d'  ckol:,,'.'xNMMMMMMMMMMMMMMMMMMMMMMMMMWKo:oKKc.'kWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWx,.. .dc   .lxoll;','.;kNMMMMMMMMMMMMMMMMMMMMMNOl:l0Xx'.:0WMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMN0xdl.    ,x,    .cllool;',,';dKWMMMMMMMMMMMMMMWXOoccdKKx,..dNMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMWXx:,,l:.    ;d.     .:;;codl;',,'':d0NMMMMMMMWNKOkxdkKKOl' .:0WMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMWO:,:xKNk;'.  :o.  .,:cll:'';col:;,''..':odk0XNNXKKK0ko:.   ':kWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMWO;'oKWMMOc:'  :xc:cc:,.  ,c;...';:;'','...  ..',,,',,.    .,''lKWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMXl.cKMMMWx. ..;odc'.       .cl;..    ..   ..      .',;lc'  .  . 'odd0NMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMXc'oNMMMWd';lc;.             ,ll,..  ...         ...'c;cc..      .  .'cOWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMNd':0MMMMKd:.                 .:o:'.  ..'''''..,,....;ldc,.            .dKWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMK:'c0WMW0o:::;,,'.             .:ol,.    ..',:l'  .,:c;.              ...cKWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMKl,,oOko:;'........             .,clc,.      .,;'.;.                    .:KMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMNOooxxdxxkkkxxdolc:..   .:lllloooox0XKkoooooloxo,.               .':ldkOKNMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWWWWWWWMMMMWX0xldKWMMMMMMMMMMMMMMMMMMMMMWNKOo;.        'cxKNWMMWNXK00000KXNWMMMMMMM    //
//    MMMMMMMMMMWXOxoc:;,,,,;;:coxOKWMMMMMKoccccccccccccccccclox0XWMWKo'   .ckNMMWKkoc,'...   ...';lx0NMMM    //
//    MMMMMMMW0o;.                 .;kWMMNl                     ..:xXMMKl,lKWMN0o,.                  .;xXM    //
//    MMMMMW0:.                     ,0MMMK,                         ,kWMWNWMNk;.                        ;0    //
//    MMMMWx.         ...''...     'OMMMMx.         ......           .xWMMW0;           ..,,,'.        ,dX    //
//    MMMMO.        :x0XNNNNX0Odc,;OWMMMNc        ;O000000Od;.        ;KMNx.         ,okKNWWWNX0d,  .cONMM    //
//    MMMWl        '0MMMMMMMMMMMMWNWMMMMO.       .xMMMMMMMMMNl        .OWx.        ,kNMMMMMMMMMMMNkdKWMMMM    //
//    MMMWl         'cdOKXWMMMMMMMMMMMMWo        ,KMMMMMMMMMWo        '0O'        :KMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMO.            ..,:ldOXWMMMMMMX;        oWMMMMMMMMWk'        cKl        ,0MMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMWO;                  .cONMMMMk.       .lOOOOOOkxo;.        ,0K,        lWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMNOl,.                .cXMMNl                            :KM0'        oWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMWXOxoc;'.           oWM0,                         .;kNMM0'        :XMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMWWMMMMMMMMMMWNKkc.        cNWx.                     .':d0WMMMMNc        .cKWMMMMMMMMMWKocxNMMMMMM    //
//    MMNd:lkKNWMMMMMMMMW0,        oWN:        'cclllllllodxOKNWMMMMMMMMO'         .cx0KXXXKOd:.   ,xXMMMM    //
//    MNl.   .';cloddddl:.        ;KMO.       .xMMMMMMMMMMMMMMMMMMMMMMMMWO,            .....         ,OWMM    //
//    Nl.                       .:KMWo        ,KMMMMMMMMMMMMMMMMMMMMMMMMMMKl.                       .cKMMM    //
//    O,                      .:kNMMX;        lWMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;.                 .;dKWMMMM    //
//    WXkoc,...         ..';lxKWMMMM0:...'''':0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkoc;,'.....',;cokKWMMMMMMM    //
//    MMMMMWX0kdlcccccldx0XWMMMMMMMMWXXXXXXXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKKKKKXNWMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SPCGIF is ERC1155Creator {
    constructor() ERC1155Creator() {}
}