// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MOVEMBER PEPE
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWXKKOdl:lol:colldx0NWWWMMWWMMMMMMMMMMMMMMMMMMMMMWXOkxxxko:cc;;:okOk0NWMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkdl;,,'...             .';;;cc::kWMMMMMMMMMMMMMMWXOxo:'.                .'clc:o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0xl'      ..............            .cdoxXWMMMMMWKkdl'    ..'...',,.......         .:kXNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkl:'.   ..''',,;::;;:;:::;;,,,'....  .       'cldOK0l.     ..,;clc:;;:cc;,,;;,,,'''....  ..',cxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk,    ..',,,;;;;,;c:;;;;:::;,,;;;,,,,',,,'..        ..  ....,;:;;;;;;,;;;:;,,:c:;,,,,,,,;,.      ;dkNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl.  ';,,;;,,,;;;;,;::;,;;,,,;;;;;::;,,,,,,;;;'...       ..';::;,;;,,;;;;;,;,,;;;;,,,,,,,,,,,'.....  .oKKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxl,. ..';:;;,,,,,;;;::;::;,,,,,,,;;,;::;,,,,,,,;:;,;,..        .,;;,,;;,,;;;,,,,;;,,,,,,,,,,,,;;,,,;;'.  ...:0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNO:    .,;;;;;;;;,,;;;;;;;;;,,,,,,;;,,,;;;;,,,,;;;,;;;;;;,,,'.      ..',,;,,;;;;;,,,,,,,,,,,,,,,,,,,,,;;,,'.    cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc.   ..',,;;,,,,;,,;;;:c:;,,;,,,,,,,,;;;::;,,,,,;::;;;:;;;;;;,..      .',;,,;,,;;;,,,,,,;;,,,,,,,,,,,,,,,;ol.   .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;    .,,,,,;;;,,,,,;;;;;;;;;,,,,,;;,,,,,'.'.......'.........',;;;'      .',,,,,,;;;,,,,,,,,,;,,,,,,,,,,,,,;cd;    .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.    .',,,,,,,,,,;;;,,,;;;;,;;,,,'''.                         ......      .',;;,,;;;;;,,,'''''............''''..    .cxkOKNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKl.   .',,,,,,,,,,,,,;:;;;;;;,''....    .........''''..........               .,;;,,''.....                                 .';dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl    .,,,,,,,,,,,;;;,;;,''...      ..',,,,,,,,,,,,,,,,,,,,,,,,,'..''...       .',...   .......''',,,,,,,,,,,,,'',''''........   .:xKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk'   .,,,,,,,,;;;;;;,....      ....',;;;,,;;,,,,,,,,,,,,,,,,,,,,,;,,,,,,'..      .....';::::;;,,;;;;,,;::;::;,;;;,,;;;;,;;;,;,,'... .;xXWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.   .,,,,,,,,,;:;;,,.     ..',,,,,;;;,,;,,,,,,,,,,,,,,,,,,,,,,,,,;,,,,,,,,'.    .';,,,;;;;;:c:;;,,;;,;;::;;;;,,,,',,,,,''',,'.''',,..  ,kWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl    .',,,,,,,,,;,,;;,'....',;;;;,,,,,,,,,,,,,,,,,,,,,'.....................       .....',,;:;;::;;,,,'''''.......   ..     ..     ....   .cdkkxx0WMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.    .,,,,,,,,;;;;;;;,;,,,,,,,,,,,,,,,,,,,,,,,,,'....         ......   .........         .',;;;;c:'...          .......''..''''.''''......       .cKMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk.   .',,,,,,,;:;;;;::;;,,,,,,,,,,,,,,,,,,,,,,'...   ....'''',,,,,,,,,,,,,,,,,,,,,'''''..    .,:'..    ..'...''',,,,,,;::;,;;;;;;;,,,,,;;,,,''...    'xNMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,  .',,,,,,,,,;:;;;,,;;;,;,,,,,,,,,,,,,,,,'...  ..',::;,,;,;;,,,,,,,,,''..............''';cc'  .   ...,,;,,,,,,,,,,,,,:c:,....................',,'.   'OMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl   .,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,..    .',::c:;;;;,,''......            ..        .',;'.  .',;,,,;;,,,,,'........        ... ...'''...   .      cXMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXd.   .,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.    ..',;;;,''..... .....,,,,;cllodxkkkk00Oxllc;'...      .,::;;;,,,'...      .',;;coxdoxxoc;,:ccdxxkkxc,,..     :KWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMNkc'.    .,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'..    ..';:;,''..  ...,::d0K0XWWWWWWWXK000XNXNWMMMMMWNXX0c.     .;;'...    '::lxkxx0NWWWMMNx;'.        ..;d0NNNX0d;.   .lKMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMXO:. ..   .',,,,,,,,,,,,,,,,,,,;,,,,,,'.     ..',,;;,..  .,lxOKXNWWMMMMMMMNXkc,......'.':oxOXWMMMMWXk:.        ..,:cdKWWWMMMMMMMMWKx;                .xWMMMMNKd'   cKWMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWk,.  .,.   .,,,,,,,,,,,,,,,,,,,,;,,'...   ...',::,...  .;xKWMMMMMMMMMMMMMNO:..               .dNMMMMMMNd.    ,dk0XNWMMMMMMMMMMMMMNd.                   .dXMMMMMMK:   'xNMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMW0x:.  .,:,.  .,,,,,,,,,,,,,,,,,,,,,'..    ...,;,'...  .':o0NMMMMMMMMMMMMMMNO:.                   'OWMMMMMMX:   .kMMMMMMMMMMMMMMMMMMMO'                      ,xNMMMMM0'   '0MMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMW0c.   .',;:;.  ',,,,,,,,,,,,,,,,,,,..    ..,,,,''.   .cx0NWMMMMMMMMMMMMMMMMK:.                      .dNMMMMMWx.  .oNMMMMMMMMMMMMMMMMMX:                        .oWMMMMK;   ,0MMMMMMMM    //
//    MMMMMMMMMMMMMMMMMKl.  .',;;;;;,. .,;,,,,,,,,,,,,,,,,,.   ........    .lOXWMMMMMMMMMMMMMMMMMMMWx.                        '0MMMMMMK,  .lNMMMMMMMMMMMMMMMMWd.                         lNMWXOl.  .dNMMMMMMMM    //
//    MMMMMMMMMMMMMMMMXl  .';;;;;;;;;,',,,,,,,,,,,,,,,,,,,,.   ..        .c0WMMMMMMMMMMMMMMMMMMMMMMWd.                        .kMMMMMNo.  .oNMMMMMMMMMMMMMMMMWk.                        .dKx:.     cXMMMMMMMMM    //
//    MMMMMMMMMMMMMMM0:   .;:;;;;:;;;;;;;,,,,,,,,,,,,,,,,,;,.      .     .oKXXNWMMMMMMMMMMMMMMMMMMMWk.                        .OMMMMXl.   ,0WMMMMMMMMMMMMMMMMMXc                        .l;       :KMMMMMMMMMM    //
//    MMMMMMMMMMMMMXd'  ..,;:;,;:c;;;;;,,,,,,,,,,,,,,,,,,,;c:,'...'::,.    ...'o0KXNMMMMMMMMMMMMMMMMXc                        ;KMMMXo.    :0XK0KXXXWWMMMWMMMMMWKc.                      .'      'oKMMMMMMMMMMM    //
//    MMMMMMMMMMMMXc.  .,;;,,,,,;;;,,,,,,,,,,,,,,,,,,,,,,,;:;,,;,;;;;::'.       ...;d0XNWWMMMMMMMMMMMKo'                     'kWWKd,       ........,;:cc:loooxdc.                              .dWMMMMMMMMMMMM    //
//    MMMMMMMMMMWO,  .';:;;;;,;;;:;,,,,,,,,,,,,,,,,,,,,,,,,;;,;:;;:;;,,,,'....       ..',:odONMMMMMMMMW0c'..              .,cONO:.                                                       ..... ,0MMMMMMMMMMMMM    //
//    MMMMMMMMMW0;   .,;:;;;;,;;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,;;;;::;;,,,,''''..            .:xk0KXWWWWNNXKOc..      .,,;loocc;.   ...  ..    ..''.........   ..........       .... ..''....  ,OWMMMMMMMMMMMMM    //
//    MMMMMMMMMNl   .';;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,,,;;;,,;;;,,;;,.       ..''...        ..';;::,:odxdc,.     ,;....      .,'.   .,..     ..,;;,;;::,,,;;;;;;,,;;,'''..''''......    'dKWMMMMMMMMMMMMMM    //
//    MMMMMMMMWk'   .,;;;;;;;;:;;,,,;;,,,,,,,,,,,,,,,,,,,,,,,;;,,,,,,,,,,,....     ...''......                              .''....    .,;,,.       .....'.....'...........  ..        .':co0WMMMMMMMMMMMMMMMM    //
//    MMMMMMMNd.    .;;;:c:;;;::;,,;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'..          .............  .  ...... ......  ..       .';,,,,,,..                           ........  .l0XWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMW0,    .';;;;::;;;;;,,;;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.. .           ................        .    .....,,,,,,,,,,,,'.       .''''............,;;''..   'xNMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMK:     .,,,,;,,,,;,,,,;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'......                  ....... .',,,,,,,,,,,,,,,,,,,,,,,..     ..',,,,,,,,,,,'''....     .:0WMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMM0'    .,,,,;,,;,;;,,,,,,,;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,...........''.......... ....          .    ',,,,,,,,,,,,,,,,,,,,,,,,,'.      ..........       ....',...lkXWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMNl.    ',,,,,,,,,,,,,,,;;,;;;;;;;,,,,,,,,,,,,,,,,,;;,,,,,,;;;,,,,,,,'... .                                 ..';:;,,,,,,,,,,,,,,,,,,,,,,,,,,.         .. .........',,,;,,..   ,kNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMK;    .',,,,,,,,,;;,,,,;;,;;;;;;,,,,,,,,,,,,,,;,,;;;,,,,,;;;;,,,,,,,,,,,','''''''................ ......''',;:cl:,,,,,,,,,,,,,,,,,,,,,',,,,'.    ...',,,,,''''.......'.        ;kKK00WMMMMMMMMMMMMM    //
//    MMMMMXc     .,,,,,,,,;;;,,;;;:;,,,,,,,,,,,,,,,,,,,,,;;,;;;,,;;,,;;;,,,,,,,,,,,,,,,,,''..',,,'..',,,,,,,,,,,,,,,,,,,;;,,,,,,,,,,,,,,,,,,,,,...,,,'......,'..''..                       ....:okXMMMMMMMMMM    //
//    MMMMMNl     .,;;;;,,,,,,,;;;::;,,,,,,,,,,,,,,,,,,,,,;::;,;;,,,,,,,,,,,,,,,,,,,,;,,..    ....    ..........,,,,,,,,'..',,,..',,,,,,,''','..  .','.  .....                                    .lXMMMMMMMMM    //
//    MMMMMWo.   .;:;;;;;;,,,;;;;;;;;,,,,,,,'..',,,,,,,,;;,;;;;;;,,,,,,,,,,,,,,,,,,,....                        .......     ..    .''....   .     ...                                             .oNMMMMMMMMM    //
//    MMMMMWx.   .;:;,,,;,,;;;::;;;;;,,,,,,.  ..,,,,,,,,;;;;;;;;,,,,,,,,,,,,,,,,,,'.                                                                                                               'xNMMMMMMMM    //
//    MMMMMWd.   .::;,,,,,,;;;;;;;;,,,,,,'.  .',,,,,,;;,;;;'..................'''..                                                                                                                 ,0MMMMMMMM    //
//    MMMMMXl.   .,;,,,,;;;,;;;:;,,,,,,,'.  .',,,,,,,,,'..   ...................                                                                                                                   ,OWMMMMMMMM    //
//    MMMMMNo.   .,,,,,,;:;;;;;:;,,;,;'.    .,,,,,,,;,.   .',;::::::::::::::;;;;.   .                                                                                                 .,;,,..   'lkXWMMMMMMMMM    //
//    MMMMMMO.   .,,,;;,,,;;;;;;,,,,,,'.    .,,,,,,,,'   '::::::::::::::::::::::,..,;;,.    ..                                                                                     .',:::;,.  .l0WMMMMMMMMMMMM    //
//    MMMMMNo     .,,,,,,,,,,,,,,,,;;;'.    ',,,,,,,'.  .;:::::::::::::::::::::::;;::::'  .,:;'....                                                  ..        ..        ..,,'..',;::::,..  .lKWMMMMMMMMMMMMMM    //
//    MMMMMWO,     .,,,,,,,,,,,,,,;;::'    .',,,,,,,.  .:::::::::;;;,,',,,,,,;;::::::::;'';:::::::;,''.....   .',,'.   ..   ....             ....   .,;,'....,;;;,'....,;;::::::::;;'..   .:kNMMMMMMMMMMMMMMMM    //
//    MMMMMMMO'    .,,,,,,,,,,,,,,;;;;'.   .',,,,,,,.  .;:::::::,....         ........',,,,,;:::c:::::::c:;,',;::::;;;;;;;,,;:::,...   .   .,:::,...,:::::;;::::::::;;;;;,,;,''''..    .;xXWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMNl    .,,,,,,,,,,,,,,,,,,,.    .',,,,,,.  .,;::::::,.  .''.............         .......''',;,..',,,;;;;,,;;;::::::::::;;;;;;,;;:::::;;::;;;;;;;,,'.''''.....              .OMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMW0:    .,,,,,,,,,,,,,,;;;,'.  ..,,,,,,,'.   .,::::::;,.. ..';:::cccc::;,'..     .'''....           ...    ..............'',,,''','''...... ..            ...     ....'''. .xWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMO'    .',,,,,,,,,,,,,,,,,'..,,,,,,,,,,'.   .';::::::;;,.. .....,;::;::::;,'..  ....';;;,,'''''''..................                  ....''...','.',,,,,;;;:.  .;:;:::;.  ,OWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMNk'     .,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.   .;:::::::::;,'...  ...',;;;;;;;;'...........:llllc:;;;;;;;;;::;;:c::;;,,'....'',',,,',:c;..;c::llcc:;;;::;;:::,. .,::::::;'  'OMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMWKl.   .',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.   ..';:::::::::::;;'...  ...',;;;;;;;:c;...  ..',:;,,::;:::;;::;;::;;;;;;;;;;;;;;;;;;:cl,   ,llc:c::;:::::::::c,  .,:::::::;. .oWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMNo.   .',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.     ...,;:::::::::::;'...   .........''''......   ....,:::ccccc::;;;;;;;;;;;;;;:::,'..  .;:c::;:;;::c::;;;,..  .';::::::::. .xWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMXc     ..',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'...      ..'',;:::::::::;,'''.....        ..,;,....    ...,;:::;;;;;;;;;;;;;;;;;'.   ..'clc::c:::cooc;,...   .';:::::::::'..lNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWKl.     .',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'...       ..';;:::::::::::::;;;;,,,,'........               ...............    .,;;;;;;,,'.......    ..',;::::::::::'. ,0MMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNOd:.    ...,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'...      ..;::::::::::::::::::::::::::;;,,,''........                    .....      ..  ......,;;::::::::::::;'  ;0WMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNd.      .,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,..     ...',;::::::::::::::::::::::::::::::::;::;;::;,''...................''',,;;;;;:::::::::::::::::::;. .oXMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWKx:.    ..',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'..      .......,;;:::::::::::::::::::::::::::::::::::::::::::;;::::::::::::::::::::::::::::::::::;,.. .dNMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNd.      ..,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'....         ....',;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;;,...  'dKWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMN0kl;.     .',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,''...        .......',;;;:::::::::::::::::::::::::::::::::::::;::::;;;;,;;,,,,''...   .:dkXWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWk;.     .'''',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'....            ......'',,;:;;,,;;;::::;;;,,''',,'''...........            'ldkKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWNOoc'      ..',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.........            ..     ....                                                                             //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MOPEPE is ERC1155Creator {
    constructor() ERC1155Creator() {}
}