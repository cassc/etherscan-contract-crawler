// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BlackCock
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXXXXNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXOdlcccclloddxkOO0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXdc::ccccc::::::ccllldOXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWkcccclllccccccclllooloooodkOKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKoccllloolooooolllllllllc;,,,;;;;coxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKdcclodddxxddxdollccclllc:;,,,,'..   ..;lx0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWKdccldxxkkkkkxxddol::::ccc:;;;,,;;'...    ..,:ok0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWXdcclodxkkOOOkkxdoolc:ccccc:ccllc;;,,'...       ..,:lloxOKXXK0O0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWKo::clodxkkOOOkkkxxdolc:;,,,,;;:::;,,,'',,.              ..'......;oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWKo;::cclodxkkOOOOOOko:'.........',,;,,'.,cl:.                        .,lkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMKl;;;;::lodxkOOOOOkdc'...','....,;:;,,,',;ccc,.                          ..;d0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMXc',,,,;:coxkO00Okxoc,....,,.''';lolc:;,'';:cl:.                              .oKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMk'..,,,,;:looooodolc;'...,cc:::codolc;;,''';cc;..                              .;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWo. .',,,,,,''.',,;:cc::ccoooodxxxxdl:;,,'..'';c:,................'',,,,,,,,'''...,kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMM0;   .'''.........';ldxddxddxkO0OOkdlc;,,''...':ll:;;:;::cclllllllllloooooddoooolcclONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMXc.    .......''.';;;:oxkdddoldkOOOkdlc:;,''.....,:ccccclooooddddddddddddddxxxddooooloxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNo.      .......',;ccc:coddddollloxxdol:;,'........',;:cloddddxxxxxxxxxxxxxxxxxddoddollcoONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWk.        ...''',;cllc::ldkOxol;,:ddolc::;,'........',;:codddxxkkkkxkkkxxxxddddooooollcllokKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNc.         ..,;;:clool::clddc,..,:lllc:;;;,'.........',,;looddxxxxxxkkxxdooolloooolllllooddx0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMX:            .',;:lodolc;,'''.':c::::,'''',''.........'',cooodxxxxxxxxdolllllloolloooddddxxxkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMX:             ..',:loool:,.';:clll:;,,,,,,'..........'',,:oodxxxxxxxxdollooolooloodddxxxxkkkkOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMX:              ..',;:ccc:,',:clc:::cllc;;,'.....  ...'',;coddxxxdddxdollooooooooddxxxxkkkkOOOOO0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMX:               ...',;;;,',;;;;:lxxxo:,''''....   ...',;:coddxdoodxkdlclooooooddxxxxkkkOOOOOOOOO0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMX:                ....','...',;cdkxl;'.';;;,'..   ...',,;:ldxddoodxkxlccllooodddxxxxkkkOOOOOO00000O0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMK;              ..,;,.......',;;;,'...;ll:,....   ...',;:ldxxdooddxdolccllooddddxxxkkkkOOOOOOOOOOOOOkk0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMK;            ..;ccllc;'..........'';::;,.....    ..',,:lodxxddddddolccccloodddddxxxxkkkkkkkOOOOkkkkxxxOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMK;           .':clloooooc;'.......'','.....      ...',:lodxxxxdddoolcccllllooodddddddxxxxkkkkkkkkkkkkkkkk0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMO'         ..,:cllloodddddl:,'..........        ...',:lodxxxxddddolllclllllooodddddooddddddxxxxxxxxkkxxxxx0XNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWd.       ..';:ccccclllloooolc:;,..................';:coodxddddddooolllllllooooooooollllloooooooodddxxxxddddxxxkOKNMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMX:     ..',;::::::::ccllllllllc::;'..............',;:cllodddddddoooolloooooooooooolcc:::::ccccllllooddddxxxdolllodkKWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMM0,  ..',;::::::::::ccllllllllllcc::;;,,,,,,,,;;;;;;::clodddddddddoooooolllooooooollc:;,,'',,;;;:clooooddddddoloddddx0NMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWx..'',;::::ccc::ccccllllllllllllccccccccccccclllccccclldxxddddddoolloollloooodoooolc:;,'......';:lloooodddddoodddddddOXWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNo,;;;;:cccccclcccccllllllllllllcccllolllooooooooolccclodxdddddddolcclccclooooddddolc:;,,'......,:cllooooooooodddddddddkXWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWOc:::::ccccllloolllloolllllllccllllooooooooodddddoolllllloddddddoolccccclooodddddoolc:;;,''......,:cllooooooooodddddddddONMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWOl:cccllllllooooooooooooollclllllllooddooooooddddddoolllloooooooooolccllccloddddddollc::;,,'.......,:llooooooooodddddxxddxKMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMW0lcccllooooooodddddddoooooolccllloooddddoooodddxxdddolllllooooooooollcclllcloddddooollc::;,,'........,clooooollooddddxxxdddKWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNdccllooodddddxxxxddddddoooooolllooooddddooodddxxxxxdolcccllllloooolllcclollloddoooollc::;;,,'.........;clooollllooddddddoodKMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMKoclooooddxxxxxxxxxxddddddoooolllooooodddoooodddxxxxddlc::::ccllccllllcclllllooooolllc::;;,,''.........';clllllccloodddoooldKMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWOllloodddxxxkkkkkxxdddoooooooollooooooooooooddddxxxxdol:::;;:::::ccclccclllllloolllcc:::;;,''...........';:ccccccclooooollcoKMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNxcloodddxxxkkkkxxddooollllloooooooooooooooodddddddxddolc:;,;;;;::cccccclllllllllcccc::;;;,,'............'',;:::::::cloollccdKMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMXdclooddddxxxxxxdoolcccccccclllllollooollloooodddddddooolc:,,,;;;::::cccccccllcccc::::;;,,,''.............'..',,;;;;:clllc::dXMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMKoclloodddddddddolc::;;;:::::cccllllloolllloooddddddoooolc:;'',;;:::::::::cccccc::::;;;,,,'......................'',;;:ccc::dXMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWkcclloodddddooollc:;,'',;;;;;:::ccllllllllooooddddxddoolcc:;,'',;;;;;:::::::::::::;;;,,,''..........................',;:::::oXMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMXo;:cloodddddolcc:;,'...',,,,;;;;::ccccclllloooooddddddolcc:;,,'',,;;;;::::::::;;:;;,,,,''................'''..........';:::;lKMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWkc:clooddxxddolc:;;,'....''',,,,;;;:::cccccllooododddooolc:;;;,'.'',,,,;;;;;;;;;;::;;,,''''...... .....'''''''''.......',',;::kWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMKo:cloddxxxxxddolcc:;,''......'',,,;;;;::::::cllodoooololcc:;;;:;'...',,,;,;;;;;,;,,,,,,,'''....  .....''''''''''......',,...';c0WMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWkcclooddxxxxxxdoollc:;,''.......''',,,,,;;;;:::ccllloollc::::::::;'.....'',,,,,'''''''''...'..  ........'''',,''''.....',;.. ..'ckXWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMKocllooddxxxxxxddollcc:;,'...   ....''',,,,;;;;:::ccccclc::::::;;'.......................................''',,,''''''.''',;,.   .,:lx0NMMMMMMMMMMMMMM    //
//    MMMMMMMMMMWOlllooddddxxxxxxddoolc:;,'.. ..........'''''',,;;;:::;;::;;,,,''',,;;,,,,'''',,,,,,,,,,,'''.............'''',,,,,,,''',,,,;:,.   .,:clxXWMMMMMMMMMMMM    //
//    MMMMMMMMMMWOlloodddddxxxxdddddolc:;,'..  .............''',,,,,,,,,,''...',;:::;;;;;;;;;:ccllllllcc:;,''''''........'',,,;;,,,,,,,,,,,,;:,.  ..;:ccxXMMMMMMMMMMMM    //
//    MMMMMMMMMMNkloodddddxxxxxdddooolc:;,.....   ...........''''..........',;:ccc:::;,;;;;;;:clllooolc::;,''''.........'',,;;;;;,,,;;;;;,,,;::,.  .';:co0MMMMMMMMMMMM    //
//    MMMMMMMMMWKdloodddxxxxxddddoollcc:;'.....     .....................',;::ccccc::;;;;;;;::cloodddolccc:;;,'''......'',,;;;;;;;;;;;;;;,,,,;::;.  ..;:cOWMMMMMMMMMMM    //
//    MMMMMMMMMKxlooddxxxxxxdddoollcc::;,'....        ..........   ...'',;;;::ccccc::;;;;;::ccllooddoollccc:;;,'''...''',,,;;;;;;;;;;;,;,,,,,;:::;.. ..;:kWMMMMMMMMMMM    //
//    MMMMMMMMXxloddxxxxxxddddoolcc:;;,,'....            ............'',,;;;;:::ccc:::::::cccllooddooollccc::;;,''''',,,,,;;;;;;;;;,,,,,,,,,,,;:::;.. ..;kWMMMMMMMMMMM    //
//    MMMMMMWKdcllodxxxxdddoooolc:;,,''.....                .........''',,,;;;::::c::ccccclllooddddddoollccc:::;,',,,,,,,;;;;;,,,;,,,,,,,,,,,,;::::;.  ..xWMMMMMMMMMMM    //
//    MMMMMW0l::::cclooooooollcc:,''.......                   ..'.'''''',,,;;;:::::cccllllllooddddddddollcccccc:;,,,,,;;;;;;;;,,,,,,,,,''''''',;;;;;,...,xWMMMMMMMMMMM    //
//    MMMMMKl;;;;;;;;::cccccc::;,'........                    ...''''''',,,;;;;::::cccllllllloddddddddoollllccc:;;;;;;;;;;;;,,,,,,,,''''''''''',,;;;;;;;;xWMMMMMMMMMMM    //
//    MMMMNx::::::;;;;,,,;:::;;,'........                      ..''''''',,,;;;;::::cclllllllooooddxxddoooolllllc:;;;;;;;;;;,,,,,,'''''''...'',;;;;;;;;;;:xWMMMMMMMMMMM    //
//    MMMMWkc::::::;;;,,,,,;;;;,'.......                       ..'.''''',,,;;;::::ccccccclcclloddddddddoollllccc:;;;;;;;;,,,,,,''''''...'',;;;;::::::::::xWMMMMMMMMMMM    //
//    MMMMMNOocc:::::;;,,''',,,'.......                        ..'''''''',,;;:::ccclcccccccclloodddddddoolllcccc:;;;;;,,,,,,,''''''.'',,;;:::::::::::::::dNMMMMMMMMMMM    //
//    MMMMMW0occcc:::;;,,''..''.......                         ..''''''',,,;;;:::ccclccccccllllooddddddoolllcccc:;;;;,,,,,''''''''',,;;::::::::::::::::::lKMMMMMMMMMMM    //
//    MMMMMNxcccccc::;,,''...''.....                           ..'''''''',,,,;;:::cclccccccccllooodddoooollcccc:::;;,,,,,''''..',;;;::::::::::::::;;:::::cOMMMMMMMMMMM    //
//    MMMMM0c;;:ccc:;;,''.....'....                             .'''''''''',,,;;;:::cccccc::cclllooooooolllcccc::;;;,,,,'''...,;::::::cccc::::::::::::;;:cOWMMMMMMMMMM    //
//    MMMMMO:,'',,;;,,,,''......... .............................'.....''''',,;;;;::::c::::;;::ccllllllllcccc::::;;,,,,''...,;:::cccccccccc:::::::::::;;;cOWMMMMMMMMMM    //
//    MMMMMXkxdl;'.'''''''............'',,;;;;;::::;;;;;;;;,,,,,,'''....'''',,,,,;;;;;;,,,;;,,;;::cccccccc::::::;;,,,''...';:::ccccccccccc:::::::::;;;;;::xNMMMMMMMMMM    //
//    MMMMMMMMWWXOl,...'''..........',,;;::::cccccccccccccc::::;;,,,'...'''',,,,,,;;;,,,,,,,,,,;;;:::::::::::::;;,,''....,;::cccccccccc::::::::::::;;;;;;:oKMMMMMMMMMM    //
//    MMMMMMMMMMMMWOc'.............',;;:cccllllllllllllllllcccccc:;,,,'...'',,,,,,,;;;:ccc:;;;;;;;;::::::::;;;;,,''.....,::::ccccccccc::::c::::::::;;;;;;;cOMMMMMMMMMM    //
//    MMMMMMMMMMMMMMXo,...........',;:cclloooooooooollolllllccllllc:;;,,'..'''',,,,;;:cclllc::::::;::::;;;;,,,,''.....';;:::::cccccccc:::cc:::;::::;;;;;;;cOWMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNk;........',;::clloooddddddooooooooooollloollc::;;;,'..'''',,,;;;::c::::;;;;;;;;;;,,,,,''......',;;;::::::::cccc:::::::::::::;;;:::;:kWMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMW0:... ..,;::ccllooddddddddddoooooooooooooooolcc:::;,'...'''',,,,,,;;;;;;;,,;;;,,,,,''........',;;;;;;;::::::::::::::::::::::::::::::xNMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMXo. ..,;::ccllloooddddddddddddddddodddooooooolc:::;;,'.....''''''''''',,,,,,,''''.......,;,'',,;;,;;;;;::::::::::::::::::::::::::::dNMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMNk:',;;::ccccllllooodooooooddddddddddoooooooolcc::;;,,'...............'..............,;;'.'',,,,,;;;;;;;;;::::::::::::::::::;;::::xNMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMXd:,;;;:::ccclllooooooooooooooooodoooooooooollc::;;;,'...........................'''..  .'',,,,,,,,;;;;;;::::::::::::::;;;;;;;;:kWMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWKxc;;;;:::ccclllllllloooooooooooooooooooollllc:::;;,,'.......................          .''',,,,,,,,;;;;;;::::::::::::;;;;;;;;:kWMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWXOdc;;:::ccccclllllllloooooooollooooolllllllcc::;;,''...............                 ..''',,,,,,,,;;;;;:::::::::;;;;;;;,,;;;xNMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc;;;::::ccccllllllloollllllllllllllllccccc:;;,''.........                        ..'''''''',,,;;;;;;;;::::;;;;;;,,,,,,,lKMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXxc;;;::::ccccclllllllllllcclllllllcccc::::;,'...                                 ..''''''',,,,,;;;;;;;;:;;;;;,,,,,,''';kWMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo;;;;;:::cccccccccccccccccccccccccc:::::;,.                                    .....'.'''',,,,;;;,;;;;;;;,,,,,''''..'lXMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkc,,;;::::::::::::::::::::::cccc:::;;;;;,.                                     ........''',,,,,,,,,,,;;,,,,''''.....;OMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo;,,;;;;;;;;;;;;;;;;;;;::::::::;;;;;,,,'.                                     .........''''',,,,,,,,,,,,'''........dWMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:,,,,,,;;;;;,,,,,;;;;;;;;;;;;;;;;,,'''.                                     ..........'''''''',,'''''''..........lNMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,''''..                                     ..........''''''''''''''............:KMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc,'''''',,,'',''''''''''''''''''....                                      ...................................,OMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXk:'''''''''''''...''''''''''........                                     ....................................dWMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXo,..'''...........................                                      ...................................:KMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMM                                                                                                                                          //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Cock is ERC721Creator {
    constructor() ERC721Creator("BlackCock", "Cock") {}
}