// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SGT_SLAUGHTERMELON
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//               _         _                   _     _                           _                            //
//              | |       | |                 | |   | |                         | |                           //
//     ___  __ _| |_   ___| | __ _ _   _  __ _| |__ | |_ ___ _ __ _ __ ___   ___| | ___  _ __                 //
//    / __|/ _` | __| / __| |/ _` | | | |/ _` | '_ \| __/ _ \ '__| '_ ` _ \ / _ \ |/ _ \| '_ \                //
//    \__ \ (_| | |_  \__ \ | (_| | |_| | (_| | | | | ||  __/ |  | | | | | |  __/ | (_) | | | |               //
//    |___/\__, |\__| |___/_|\__,_|\__,_|\__, |_| |_|\__\___|_|  |_| |_| |_|\___|_|\___/|_| |_|               //
//          __/ | ______                  __/ |                                                               //
//         |___/ |______|                |___/                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMN0KNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMNOxOKKKKXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMW0xO00kxxxk0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMW0xO0OkdddddxxxkOKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMWKxk0OxdooooddddddxxkO0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMXxk00kollllooooooolodddxkO0XNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMNkxO0kdlllllllllc:,;loddddxxxkO0KNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMWOdO0Odlccccclllc,..,looodddxxxxxxkO0KNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMKxx0Oxocccccccclc,';clooooddddxxxxxxxkkO0XNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMNkdOOkdlc:::ccccccclllloooodddddxxxxxxxxxxkkO0KNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMKdxOOxoc:::::cccccccllllooooodddddddxxxxxxxxxxkkkO0KXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MWOokOkdl:::::::cccccclllllllooooooddddddxxxxxxxxxxxxxkO0KXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MXddkOxoc:::::::::cccccclllllllllooooodddddddddddxxxxxxxxxkO0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    M0odkkxoc:;;;;;::::cccccccclllllllllooooooddddddddddddddxxxxxxkO0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    Wklxkkdlc:;;;;;;::::::ccccccccclllllllclooooooooooooddddddddxxddxkkO0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    Nxlxkkdlc:;;;;;;;;:::::::ccccccccccc:,,:llllllllooooooooddddoc::ldxxxxkO0KXNWMMMMMMMMMMMMMMMMMMMMMMM    //
//    Nxlxkkdlc:;;,,;;;;;:;;:::::::::ccc:,..':cllllllllllllloooooc;''':ddddxxxxxkk0KXNWMMMMMMMMMMMMMMMMMMM    //
//    Wklxkkdlc:;;,,,,;;;,',;;:::::::::::,.':ccccccccllllllllllll:...,coodddddddxxxxxkO0XNWMMMMMMMMMMMMMMM    //
//    WOldkkdoc:;;,,,,;,...';;;;;:::::::::;:cccccccccccccccccccclc;;:clooooodddddddddddddxO0XNWMMMMMMMMMMM    //
//    MKooxkxoc:;;,,,,,,..',;;;;;;;;:::::::::::cccccccccccccccccccccllllllooooooooooooooooodxk0XNWWMMMMMMM    //
//    MNxldkxdlc:;;,,,,,,,,,,;;;;;;;;;;::::::::::::ccccccccccccccccccccllllllllllllllllllooodxk0KXXNNWWWMM    //
//    MM0llxkxoc:;;,,,,,,,,,,,,,;;;;;;;;;;::::::::::::::::::ccccccccccccccccccccllllllllllodxk0KXXKKKOxxKW    //
//    MMNxcdxxdl::;;,,,,,,,,,,,,,,;;;;;;;;;;;;;;;;;::::::::::::::::::::ccccccccccc:::ccllodxk0KKXKK0ko:cOW    //
//    MMMKoldxxoc::;;;,,,,,,,,,,,,,,;;;;;;;;;;;;;;;;;;;;;;:::::::::::::::::::ccc:,,,,:llodxO0KKKK0OxlccoXM    //
//    MMMW0lldxxolc:;;;,,,,,,,,,,,,,,,,,,;,;;;;;;;;;;;;;;;;;;;;::::::::::::::::;....'clodkO0KKKK0OdccccOWM    //
//    MMMMWOlldxxdlc::;;,,,,,,,,,,,,,,,,,,,,,,,,;,,;;;;;;;;;;;;;;;;:::;;:::::::,....:ldxO0KKKK0OxoccccdXMM    //
//    MMMMMW0ocdxxxdl::;;;,,,,,,,,,,,,'',,,,,,,,,,,,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;codkO0KKK00kdlccccoKMMM    //
//    MMMMMMWKdcodxxdoc::;;;;,,,,,,,'..'',,,,,,,,,,,,,,,,,,,,;;;,''',;;;;;;;;;::clodkO0KKK00Oxoc:ccclOWMMM    //
//    MMMMMMMMNkccoxxxdoc:::;;;;,,,'...',,,,,,,,,,,,,,,,,,,,,,,'....,;;;;;;;:cclodkO00KK00Okoc:::cclkNMMMM    //
//    MMMMMMMMMW0ocldxxxdolcc:::;;;,''',,,,,,,,,,,,,,,,,,,,,,,,'...',;;;;::clodxkO00K000Okdl:;::c:ckNMMMMM    //
//    MMMMMMMMMMMNOlcldxxkxxdoolcc::;;;;;,,,,,,,,,,,,,,,,,,,,,,,,,,;;;::cclodxkO00000OOxoc:;;;:::lkNMMMMMM    //
//    MMMMMMMMMMMMMNkl:codxkkkkxddollcc:::;;;;;;;;;;;;;;;;;;;;;;;:::ccllodxkOO0000OOkdlc;;;;::::o0WMMMMMMM    //
//    MMMMMMMMMMMMMMMNOdccldxxkkOkkkxddollcc:::::::::::::::::cccllloodxxkOO0000OOkdoc:;;;;::cclxXWMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWXkdlcldxkkOOOOOkkxddoollllllllllllooodddxxkkOOO00000Okxdoc:;;;;:::cloxKWMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWXOdlclodxkkOOOOOOOkkkkxxkxkkkkkkkOOOO0000000OOkkxol:;;;;;::cccldkKWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWX0xdlcclodxxkkOOOOOO00000000000000OOOOkkxdoc::;;;;::;:cclox0XWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xolc::ccloodxxxxkkkkkkkkkxxddollc::;;;::ccclcccldkKNWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0kdolc:;;;;::::::::::::::::::ccclooooddxkOKXWWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNK0OkxdoolllllllllooodddddxxkO0KXNWWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNNNNNNNNNNNNNNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SGTSL8RMLN is ERC721Creator {
    constructor() ERC721Creator("SGT_SLAUGHTERMELON", "SGTSL8RMLN") {}
}