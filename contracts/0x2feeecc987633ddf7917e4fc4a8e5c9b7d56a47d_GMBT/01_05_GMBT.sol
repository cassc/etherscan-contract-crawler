// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gambit
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNNWWMMMMMMMMMMMMMWNNNNWWMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMM0kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkdlc::cldkXWMMMMMMWXOdlc:::cokKWMMMMMMM    //
//    MMMMMMMMMMMMMMMMMK;.xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd:'...'..''':dKWMMWKd:''....''.';oKWMMMMM    //
//    MMMMMMMMMMMMMMMMK:  .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c''.''''''''..':kNWOc'..''....'.''':OWMMMM    //
//    MMMMMMMMMMMMMMWO,    .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl'....'''''''...';xk:'.........''''''cKMMMM    //
//    MMMMMMMMMMMMMKl.       ;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0:......'.........',;'''........'''.'.;OWMMM    //
//    MMMMMMMMMMWXd'          .cOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc'.''.'''..''....'''..'''.......''...:0MMMM    //
//    MMMMMMMMWKo'              .:ONMMMMMMMMMMMMMMMMMMMMMMMMMMNx,''..'....'''...''''''''..'''..'''.'dNMMMM    //
//    MMMMMMW0l.                  .;kNMMMMMMMMMMMMMMMMMMMMMMMMMXo,.''.....'''....''''.''...''..''.'lKMMMMM    //
//    MMMMWKl.                       ;kNMMMMMMMMMMMMMMMMMMMMMMMMXd,'''........'.......''...''.''''l0WMMMMM    //
//    MMMXd.                          .:0WMMMMMMMMMMMMMMMMMMMMMMMNk:''..'''....''...........'''',oKWMMMMMM    //
//    MMXc                              'kWMMMMMMMMMMMMMMMMMMMMMMMW0l,...''''.......''''....'.':xNMMMMMMMM    //
//    MWo                                ,KMMMMMMMMMMMMMMMMMMMMMMMMMNx:''''''''.....''''''''.,l0WMMMMMMMMM    //
//    MX;                                .kMMMMMMMMMMMMMMMMMMMMMMMMMMW0l,'''..''......'''''':kNMMMMMMMMMMM    //
//    MNc                                .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;'...''''....'''',oKWMMMMMMMMMMMM    //
//    MMO'            .c:;l'            .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l,.''''''..''.':kNMMMMMMMMMMMMMM    //
//    MMWKl.        .c0Xc'OXd,.       .;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXx;'''...'''',lKWMMMMMMMMMMMMMMM    //
//    MMMMWKkoc::cokXWMO. oWMN0dlc:cld0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOc'''..''';xXWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMK:  .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl,'''.':OWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMW0;    .xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo,..'c0WMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWKo.      .:ONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo,'c0WMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMWX0x:.          .,oOKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl:OWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMW0dlc;..                 .,:lokNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0ONMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMW0xxxxxxxxxxxxxxxxxxxxxxxxxxxxkNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWNXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOOOO0XWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMW0l:kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd:'.    ..;o0WMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNO:'.,dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.            .lKMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMXx;'''.'l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:                ,0MMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMW0l,.'''''':kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo                  cNMMMMMMMMMMMMM    //
//    MMMMMMMMMMMNk:'..'''''..,oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:                  ,KMMMMMMMMMMMMM    //
//    MMMMMMMMMWKo,'......'....':ONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo                  cNMMMMMMMMMMMMM    //
//    MMMMMMMMNk:'.''.'.....''''.,oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXK000KO;                ,kK0000XWMMMMMMM    //
//    MMMMMMWKo,''..''.''..'''.'''':kNMMMMMMMMMMMMMMMMMMMMMMMMW0o;... ...'.               .'..  ..,lONMMMM    //
//    MMMMWXx;'.''.'...'''....''''..,o0WMMMMMMMMMMMMMMMMMMMMMKl.                                    .cKMMM    //
//    MMMNOc'...........'......''''..';xXWMMMMMMMMMMMMMMMMMMK:                                        ,0MM    //
//    MMWk;'......'''....'''....''....',oXMMMMMMMMMMMMMMMMMWd.                                         lNM    //
//    MMWXx:'..'.........'''.........',o0WMMMMMMMMMMMMMMMMMNc                                          ;KM    //
//    MMMMWKo,''.....'''''...''.'...'cONMMMMMMMMMMMMMMMMMMMWl                    ..                    cNM    //
//    MMMMMMNOc'''..'''......'''..';dXWMMMMMMMMMMMMMMMMMMMMM0'                 .lccl.                 .kWM    //
//    MMMMMMMWXd;'.'''........''.,l0WMMMMMMMMMMMMMMMMMMMMMMMWO,               ;OK:;00:.              'kWMM    //
//    MMMMMMMMMW0l'.'''.......'';xXMMMMMMMMMMMMMMMMMMMMMMMMMMMXd;.         'cONMk..xWWOl'.        .,oKMMMM    //
//    MMMMMMMMMMWXx;'''''''.'',l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxolcclox0NWMMK;  ,0WMMN0xolcccox0NMMMMMM    //
//    MMMMMMMMMMMMWOc'..''''';dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0;    ,OWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWKo,.'''':ONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo.      .lKWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNx;'.,lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKkc.          .:xKNWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWO:;dXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxol:'.                .';cox0WMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWK0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOdoooooooooooooooooooooooooookNMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GMBT is ERC1155Creator {
    constructor() ERC1155Creator("Gambit", "GMBT") {}
}