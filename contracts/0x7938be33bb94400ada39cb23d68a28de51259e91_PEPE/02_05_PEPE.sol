// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PEPE'S PHOTO
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                                                                      //
//      ____   _____  ____   _____  _  ____    ____   _   _   ___  _____  ___           //
//     |  _ \ | ____||  _ \ | ____|( )/ ___|  |  _ \ | | | | / _ \|_   _|/ _ \          //
//     | |_) ||  _|  | |_) ||  _|  |/ \___ \  | |_) || |_| || | | | | | | | | |         //
//     |  __/ | |___ |  __/ | |___     ___) | |  __/ |  _  || |_| | | | | |_| |         //
//     |_|    |_____||_|    |_____|   |____/  |_|    |_| |_| \___/  |_|  \___/          //
//                                                                                      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWXK0OkxdddxkkO0KXWMMMMMMMMWNXKKKKXWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNKkxdollllllllllllcllxk0NWX0kxdollcclloxOXWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNOoccclllllccccc::::::::;:cc::cllllllllcc:;:oOKKXNWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMN0occlllc:::::ccccccccccccccc::::::clllc:;;::::ccclodxOXMMMMMMMMM    //
//    MMMMMMMMMMMWXxlllllc:;::cllllllcccc:::::::::::;,;::clllccc::::::::,,cdk0XWMMMM    //
//    MMMMMMMMMMWKollllllllllllcc:;:::;;::clooodddddolc:::;:::::;:::cclloollccldOXWM    //
//    MMMMMMMMMMKolllllllllllllc;,,:oxkO0KXNNWNXOxxkKXX0kl,;clodxxOO0KKOxxk00OkdclOW    //
//    MMMMMMMMMNdcllllllllllc:ldxk0XNMMMMMMW0xl'.   'xWMMNkdONWMMMMMW0:.  .,xNMWKxkN    //
//    MMMMMMMMW0lcllllllllllc:l0NMMMMMMMMMMO'        ,KMMMWK0WMMMMMMK,      .OMMMW0K    //
//    MMMMMMWKxlclllllllllllllcldOXWMMMMMMWl         '0MMMMX0XMMMMMM0'      .kMMMW0K    //
//    MMMMWKxlllllllllllllllllllc:lx0NMMMMW0;.      .oNMMMMKooxOXWMMNx'    .dNMMMX0N    //
//    MMMNklclllllllllllllllllllc:;:cdk0XNWMX0xl::coOWMMWNOc,;::cldxO00kxxOKNNXKkkXM    //
//    MMNd:cllllllllllllllllllllllc;;:::lodkkOO0000000Okd:;::;;:c:,',;:loddoolccl0WM    //
//    MNx:clllllllllllllllllllc:::clP:::::;;;;;::cc::;;;;;clll:;;:cc::::::::;cxKNMMM    //
//    M0ccllllllllllllllllllllA:;:::::::::;;;;;;;;;;,;:cclllllll:;,;::::::cc:oKMMMMM    //
//    Ndclllllllllllc:clllllllllllllccO::::::::::::ccllllllllllllc;,;::::ccllcl0WMMM    //
//    0lclllllllllc:;:c:::::;::cLllllllllllllllllllllllllllllllllllc;cllllllllclkXWM    //
//    Ocllllllllll:;cc;;::c::::;::::::::Oclllllllllllllllllllllllllllllllllc:;;;:lOW    //
//    0llllllllllllcl:,:Ccc:;;:::c:::;;;;;;;;;;;;::::cccllllllllllccc::;;;;;;;::;l0W    //
//    Nxlllllllllllll:,;:cR;'',,,,,;;:::cccc::::;;;;;;;;;;:;;;;;;;;;;;;;;::::clokXMM    //
//    MKolllllllllllllE;;;::;,,;;;;;;;;;;;;;;;;;;;;;::::::;;;;;;::::ccc;,;;;:xXWMMMM    //
//    MW0dllllllllllllllM:;;:c:;,,,;::::;;;;;;;;,,,,,,,;;;;,,,;oOO00KXXOo:::::dXMMMM    //
//    MMMXklllllllllllllllO:;;;::;;,;;:oddllc:::;:::::::::::::;lKMMMMMMMWKdc:c:dNMMM    //
//    MMMMWOlccllllllllllllllN:;;;:c::ldkOKXXXK0kxdoc;;:::::::;cKMMMMMMMMWOc:ccl0MMM    //
//    MMMMMWXxlcclllllllllllllllA:;;;:::::clodxkkO00kxol:;;;:co0WWWWNXKOxoc:cc:dXMMM    //
//    MMMMMMMMNKOxdllllllllllllllllc:;;;;::ccc::::ccclllc:;;:coddddoolc:;;;;:lkXMMMM    //
//    MMMMMMMMMMMMNKOxocclllllllllllllcc:::::::::::::ccccccc:::;;;;;;;;;;;;;oXMMMMMM    //
//    MMMMMMMMMMMMMMMWX0xolcclllllllllllllllccccc:::;;;;;;;;;;;:::::ccllloxONMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWX0kxdoollllllllllllllllllllllcccllllllllcclodk0XWMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWNX0OkxdollcccccccccccccccccccllodxkO0KNWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKKK0KK0000OOOO202200KXNNWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMBY|PAOLOCREMONAMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                      //
//                                                                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////


contract PEPE is ERC1155Creator {
    constructor() ERC1155Creator() {}
}