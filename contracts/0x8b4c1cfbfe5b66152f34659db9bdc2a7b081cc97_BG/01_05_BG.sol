// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BEEPLE GAMBIT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMWWMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWMMWWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWWXKOkxxxddxxxkOKXWWMMMMMMMMMMMMMWWX0kxddoooooodxkOKNWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWWXOxoc:;,,,,,,,,,,;;clxOXWMMMMMMMWN0xoc;;,,,,,,,,,,,,,;cokKWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWN0dc:;;,,,,,,,,,,,,,,,,,,;ck0XWMMMNOo:;;,,,,,,,,,,,,,,,,,,,,:oONWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWN0o::llc;,,,,;;;;;;;;;,,,,,,,,;cONWKo:ccc;,,,,;;;;;:;;;;;;,,,,,,;o0NMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMXx::lxkxl:,,,;;:::::::::;;,,,,,,,;odc:ldoc;,,,;;:::ccccc:::;;;,,,,,:xXWMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWXd:cokOOxc;,,,,;:::ccccc:::;;,,,,,,,,;cllc;,,,;;:::cccccccccc::;,,,,,;dXWMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWXd::ldkkdl;,,,,,;;::ccccccc:::;;,,,,,,,;;;;,,,,;;::ccccclcccccc::;;,,,,;dNMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWx:::coddc;,,,,,,,;;::cccccccc::;;,,,,,,,,,,,,,;;::ccccclllccccc::;;,,,,,:kWMMMMMMMM    //
//    MMMMMMMMMMMMMMMWKl;cccclc;,,,,,,,,,,;;::cccccccc::::;;;;;,,,,;;;:::ccccccccccccc:;;,,,,,,,oXWMMMMMMM    //
//    MMMMMMMMMMMMMMMWk:coolc:;,,,,,,,,,,,,;;;::ccccccccccc::::;;;;;;:::::ccccccccc:::;;,,,,,,,,:OWMMMMMMM    //
//    MMMMMMMMMMMMMMMNd;lxxdl:,,,,,,,,,,,,,,,,;;::ccccccccccc:::;;;::::::::::::::::;;;;,,,,,,,,,;kWMMMMMMM    //
//    MMMMMMMMMMMMMMMNd;:lolc:;,,,,,,,,,,,,,,,,,;;;::::ccccc::::;;;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,;kWMMMMMMM    //
//    MMMMMMMMMMMMMMMNx;,,;;:;;;,,,,,,,,,,,,,,,,,,,,;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'':OWMMMMMMM    //
//    MMMMMMMMMMMMMMMWO:,,,;;;;;;;,;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'''lXMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNd,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,''';kWMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWKl,;;:::::;;;;;;;;;;;;;;;;;BEEPLE=GOAT;;;;;;;;;;,;;;,,,,,,,,,,,,,,,,''''dNWMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMW0c,;;:::::::::::::::::::::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,'''oXMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMW0c,;;:::::::::::::::::::::::::::::::::::::::::::::;;;;;;;;;;;,,,,'''oXWMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWKo;;;;;:::::::::::::::::::::::::::::::::::::::::::;;;;;;;;;;,,,'',xNMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWXx:,;;;;::::::::::::::::::::::::::::::::::::::::;;;;;;;;;,,,,'':ONMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWW0l;,;;;;;::::::::::::::::::::::::::::::::::;;;;;;;;;;;,,,'',dXWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMNkl;,;;;;;;::::::::::::::::::::::::::;;;;;;;;;;;;;;,,,'',l0WWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWXkl;,;;;;;;;;:;;:::::::::::::;:::;;;;;;;;;;;;;;,,,'',lONWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWWWNOl;,,;;;;;;;;;;;;;;;::::::;;;;;;;;;;;;;;;;,,,'';o0NWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0dc;,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,'',cxKWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOo:,,;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,'':oONMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXko:;,;;;;;;;;;;;;;;;;;;;;,,,,'';okXWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOo:,,;;;;;;;;;;;;;;;,,,'';lkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXko:;;;;;;;;;;;;,,,';lxKWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWXkl:;;;;;;;;,,,:d0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xoc;;;,,;lkXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNOdllxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BG is ERC721Creator {
    constructor() ERC721Creator("BEEPLE GAMBIT", "BG") {}
}