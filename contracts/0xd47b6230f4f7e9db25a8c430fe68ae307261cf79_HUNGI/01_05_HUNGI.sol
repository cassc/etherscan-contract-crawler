// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OG SAFETYAPPLES
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOclKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx':KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO,:KMMMMMMMMMMMMMMMMMMMMMMWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK::KMMMMMMMMMMMMMMWWXK0OkxddddddxkO0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo;OWMMMMMMMMMNXKkdocc:cc::::;;;;;;:codkKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:dWMMMMMMN0xlc:;;:::::::::::::::::::;;:lx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWdc0MMMWXkl;,;;;::::::::::::::::::::::::::coONWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKcdWWXkc;;;;;::::::::::::::::::::::::cccc::coONMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0Okkkkklckkc;;;:::::::::::cc::::::::::ccccccccc:::::o0WMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOdoc:;,,,,,,,,,,,,;;;:ccclc:::ccccccccccccccccccccccc::::::lkNMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKxl:;,,,,;;;;;;;;:;,,,,,;cccc::;;:ccccccccccc:cccccccccc:::::::ccxXMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMXkl;;;;;;;;;;;;;;;;;;:;,,,,,::;;;;;:ccccccccccccccllllccccc:::::::::cxXMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNkc,,,;;;;;;;;;;:::::::;;,,'',;;;;;;::cccccccllccccccllllllccc:cc::::;:cxXMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMKo,',,;;;;;;;:ccccllc:;;;,,,,,;;:::::cccccccclllllllccccllllccccccc:::;;;:xNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMW0c'',,,;;;;;;;:ccclooolc::::::::cccclccccccccccccccccccccccccccccclccc:::::ckWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMW0:'''',,;:;;:::ccccclloollcc:::cccclllcccccccccccccccccccccccccccclllcc::::::oKMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMKc''''',;:;;:::clccccccccccc:::::cccccccc::::::::ccccccccccccccllcllclcc:::;;;:kWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNd'.'''',;;;::::cccclcccccc::::::::ccccc:::::::::cc:cccccccccccdOOxlllllcc::;;;;oXMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMM0;..'''',;;;;:::ccccccllcccc:::::::::::c::::::::::::ccccccccccdK0xdoclllcc::;;;:l0MMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWx'..',;;,,,;;::ldoccccllcccc:::::::::::::::::::::lxoccccccllcoKXxcccllclccc::;:clOWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNo..'.;k0c,,;;::oKOlcccllccc:::::::::::::::::;;;::oK0occcclllckN0occcllcclcc::;:cckWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMXl..'.'dNx,,;;:;:kNx:ccllcccc:::::::::::::::;;;:::cxXOlcccllllONOlllcllcoxkdc:;:::xNMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMXc...'.:0Kc,;;;;;dNOc:cllccccc:::::::::::::::;;;:::cOXxcccccco0NklloxOO0KKXXd::;::dNMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMXl.....'dNx,,;;;ckNXd:cllccccc:::::::::ccodl:;;;;:::o0Ko::cccl0Nxco0NWWKdlONx::;::xNMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWd'.....:00:,;;:kKXNk::cllccccccoxoc:::ld0WXOdc::::::dXOc:cc:l0NxcloONKdccxNOc::;:kWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWk,....,oKNd,;lOKxdXO:;:o0xccc:oKWKo:c:clkNXO00xl::::l0Ko:cc:ckNOookKKdllcoKKo::;cOWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMXc....:OWWKxk0Oo;c0Kl,;l0Ko::ckNNNOl:c::dXNxcokOOxdoxX0o:::c:lk0O00kocccccxXOc:;oXMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWk,..'',oKWOoc;,,;kNd,,;oKOl:dKKdOXkc::ccxKkc::ldxkOOOdc::::::cccccccccccclOXx::kWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMXo''''''dNO;''','oNk;,;;o00OK0o:lk0Odlccccc:::ccccccccc::c::c:::::::ccccccokxclKWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMKc''''':0Nd''''':O0l,,;;codoc:::cclcccccc:::::cccccccc::::::::::::::cccc:::;cOWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMW0:'''''oXx,''''';c:,,,;;;::::::::::::c:::::::ccccccc:::::::::::::::c::::;;:dNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMW0c'''',:;''..''''',,,,,;;::;;:::::::::::::::ccccc::::::::::::::::c:::;;;;oXMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMW0c'''''''..'''',,,,,,,;;;;;;;;;;;;;;;;:;;:::ccc::::::::::::::cccc::::;;oKWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMXo,'''''..'.'',,',,,,;,,;;;;,,,,,,;;;;;;::::::::::::::::::::c::::;:::oKWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:''''''''',,,''',,,,,,,,,,,,,,,,;;;;;;:::::;;;;::::::c::cc::::;;:xXMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXd;''''''','''''''',,,,,,,,,',,,,;;;;;;::;;;;;;::::::::ccccccc:lONMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo;...'',,'''''''''''''''''''',,,,;;;;;;;;;;;;::::ccccccccclxXWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKx:'..'''''''',''''''''''''''''',,,,,,,,,;;;:::cccccccclxKWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo;'...''.''''''''...''''''''',,,,,,,,;;;;:::::c:clxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdc,....................''''',,,,,,;;;::::::ldOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxoc;,'........,,,....''''''',,,;;;:coxOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0OkkkOO0KXKOxolcc:;;;;:cloxk0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNXXXXXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HUNGI is ERC1155Creator {
    constructor() ERC1155Creator("OG SAFETYAPPLES", "HUNGI") {}
}