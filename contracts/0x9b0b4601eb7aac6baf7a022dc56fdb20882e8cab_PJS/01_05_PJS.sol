// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pedro J. Saavedra
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                         //
//     _______  _______  ______   _______  _______   _________   _______  _______  _______           _______  ______   _______  _______                                                                                    //
//    (  ____ )(  ____ \(  __  \ (  ____ )(  ___  )  \__    _/  (  ____ \(  ___  )(  ___  )|\     /|(  ____ \(  __  \ (  ____ )(  ___  )                                                                                   //
//    | (    )|| (    \/| (  \  )| (    )|| (   ) |     )  (    | (    \/| (   ) || (   ) || )   ( || (    \/| (  \  )| (    )|| (   ) |                                                                                   //
//    | (____)|| (__    | |   ) || (____)|| |   | |     |  |    | (_____ | (___) || (___) || |   | || (__    | |   ) || (____)|| (___) |                                                                                   //
//    |  _____)|  __)   | |   | ||     __)| |   | |     |  |    (_____  )|  ___  ||  ___  |( (   ) )|  __)   | |   | ||     __)|  ___  |                                                                                   //
//    | (      | (      | |   ) || (\ (   | |   | |     |  |          ) || (   ) || (   ) | \ \_/ / | (      | |   ) || (\ (   | (   ) |                                                                                   //
//    | )      | (____/\| (__/  )| ) \ \__| (___) |  |\_)  )_   /\____) || )   ( || )   ( |  \   /  | (____/\| (__/  )| ) \ \__| )   ( |                                                                                   //
//    |/       (_______/(______/ |/   \__/(_______)  (____/(_)  \_______)|/     \||/     \|   \_/   (_______/(______/ |/   \__/|/     \|                                                                                   //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdl;.             ..      ..  .      .....':oxd:.......................                                                                                                                 //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxo;..        .   ..  ...........        ....':oxd:'......................                                                                                                                 //
//    xxxxxxxxxxxkkkkkkkkxxxxxxo:;.      .   ...  ....,,,:;.'....    ..   ...':odo:'.....................'                                                                                                                 //
//    xxxxxxxxxkkkkkkkkkkkxxxxd,.        ... .',....''.',;ll;,',:'........  ..,ldc,......''',;;;::;;:;;;;,                                                                                                                 //
//    xxxxxxxkkkkkkkkkkkkkkxxxc,.         ....','',;;;;;;:odlloxxdc:;......   .cdl;;;;;;;;;:ccccccccccc:::                                                                                                                 //
//    xxxxxxkkkkkkkkkkkkkkxxxl..         ..';clc:;cloddxxkkOkOKKK00Oko;.....  .;c:;,;ccccclloollcclloooodd                                                                                                                 //
//    xxxxxxkkkkkkkkkkkkkkkxc'.      ..,:clddxxxxxk0KKXXXXNXXXNNXKKKK0xc'...   .:cc::cllllooodddxdddoolc::                                                                                                                 //
//    xxxxxxkkkkkkkkkkkkkkko;cc.   ..,cdxxkkxkOOO0KKXXXXNNNNNNNNXXKKK0ko:'...  .:dddxxdddoolcc:;,'...                                                                                                                      //
//    xxxxxxxkkkkkkkkkkkkkko:oc.  ..,:odxkkkkk00O0KKKKXXXNNNNNNNXXKK0Odlc;'.....,llc:;,'...                                                                                                                                //
//    xxxxxxxkkkkkkkkkkkkkkdoo;   .':coxkOOOOO0000KKKKKXXXNNNNNNXXK0Odl::,'....                                                                                                                                            //
//    xxxxxxxxkkkkkkkkkkkkxxxxc.  .';cdkO0000KK0O0KKKKXXXXNNNXXXXXK0kdlc;'...                                                                                                                                              //
//    xxxxxxxxxxxxxxxkxkkkxxxxl.  ..',coxkO0KKXKkO000KKKKKXXXXXXXXK00Okdc,....                                                                                                                                             //
//    xxxxxxxxxxxxxxxxxxxxxxxxl.  .';,,;coodk0KOdxOkxkkxxdxxxxxkkO0KKKKOd;''..                                                                                                                                             //
//    xxxxxxxxxxxxxxxxxxxxxxxxo, ........,,,;o0Olco:,;'......',;:cdO0KKKOc'......                                                                                                                                          //
//    xxxxxxxxxxxxxxxxxxxxxxxxxl.            .okxol,........';loolcoO0KK0d,.':ooo;...                                                                                                                                      //
//    xxxxxxxxxxxxxxxxxxxxxxxxxo,             ,dO0Odc,...',...;cclxkO0KK0k:':xkocc'.......................                                                                                                                 //
//    xxxxxxxxxxxxxxxxxxxxxxdddd:..   .. ...  ,kKNXOxl;'';cc:cdddk0KKXXKK0l,:ok0kl,.......................                                                                                                                 //
//    xxxxxxxxxxxxxxxxxxxxxxdddd:..   ........:OXNXK0Odc::;:cldkKXXNNXXKK0dclllk0o,.......................                                                                                                                 //
//    xxxxxxxxxxxxxxxxxddxxdddddc.........''..l0NNXXXXXK0OkkkOKXNNNNNXXKK0kx0Ok00l,,''''''................                                                                                                                 //
//    xxxxxxxxxxxxxxxxddddddddddo;..,;;;;;:;.;xKNNXXXXXNNNNXXXXNNXXXXKKK00kdOXKKx:;;,,,,,'''''''''........                                                                                                                 //
//    xxxxxxxxxxxxxdddddddddddddd;..,cloool,,dOKNNXXKK0KKXXXXXXXKKK00KK000xokKKkc;;;;;;;,,,,,,,,'''''.....                                                                                                                 //
//    xxxxxxxdddddddddddddddddddl' ..,:lol:.,ok0KKKKKKOxdk0KKXXKKK0000000Oo:d0kl:::::;;;;;;;,,,,,,,'''''''                                                                                                                 //
//    dddxxxxddddddddddddddddddo:.  ..,:c:'..'cdxdl:cx0OxdxO0KKKKK000000kxc':olc::::::::;;;;;;;;;,,,,,''''                                                                                                                 //
//    dddddxxxddddddddddddddddoc'.   ..,;,.    .;cc:cx0KKK0O0KKKKKK000Okxo;.'clccccccc::::::;;;;;;;;,,,,,,                                                                                                                 //
//    dddddddddddddddddddddoodo:.    .....      ...,;::ldxOO0KKKKK00OOkdl;. .;cllllcccc:::::::::;;;;;;,,,,                                                                                                                 //
//    dddddddddddddddddddoooool;.     ..         ....'.',:ccoxO000Okxddl;.  .,cllllllccccccc::::::;;;;;;,,                                                                                                                 //
//    ddddddddddddddddoooooooo:.                       ......;okOkxdlc:,.....,lollllllcccccccc:::::;;;;;;;                                                                                                                 //
//    ddddddddddoooooooooooool:'.             ..''',,,,;;;,. .,odlc;,'..  . .,:ccllllllllccccccc::::::;;;;                                                                                                                 //
//    ddddddoooooooooooooooollc'.             ......';coooc'...;:,....    ..   ...,cllllllccccccc::::;;;;;                                                                                                                 //
//    ooooooooooooooooolllllllc,.                   ..;lodo:'...'...      .;;      .;cllllllcccccc:::;;;;;                                                                                                                 //
//    oooooooooooooollllllllllc;..            .......';cclc;'. ....      .,xxc.    ..';llllllccccc:::;;;;;                                                                                                                 //
//    ooooooooooollllllllccccc:;'.           ..........,,,;,.            ,dOOOxo;. .'..;cllllccccc::::;;;;                                                                                                                 //
//    ooooolllllllllllcccccccc:;'..          ....  ....''....           .lkOO0000l..'..,;:llllcccc:::::;;;                                                                                                                 //
//    ooooolllllllllccccc:::::::;'.         .         ....            ..cxkOO00Kk,...',,,,;;:cccccc::::;;;                                                                                                                 //
//    ooooolllllllcccc::::::;;;;;;'.       ..        . ...           .'cxkO000KO:....''''''...',;:::::::;;                                                                                                                 //
//    ooooolllllccccc:::;;;;;;,,,,,..                               .:ldkO0K00Ol.....'''...........',,;;;;                                                                                                                 //
//    oolllllllcccc:::;;;,,,,,,,'...                              .':lldk00KK0d'... .'''....'''..........'                                                                                                                 //
//    clllllllcccc:::;;,,,'''...                                 .'clcokO00KKk;...  .',''''...............                                                                                                                 //
//    ',;:ccccc:::::;;,,,''..                                    .;clodkO000Oc.... .;c;,,''...............                                                                                                                 //
//    ....',;:::::;;;,,'..                                    ...;ccldxkOO0Oo.....  .;;;,''....   ... ....                                                                                                                 //
//    ........',;;;,'..                                    ...',:llodxkOO00x' ....   .;;,'''...                                                                                                                            //
//    ..............                                      ....';codxxkO000d'  ....   .;;;''''..                                                                                                                            //
//    ..........                                           ...':oxOO00KKOl.   .....   ';;,,,'''.                                                                                                                           //
//    .........                                      ..'''...':oxO00000x,.   ......   .,;,,,''''.                                                                                                                          //
//    .......                                   .....';cllc:;:ldkOOOOOl...  ..,,...    .........                                                                                                                           //
//    .....                                     ...',:loooolcoxxkkkkxc...   .:lc;.                                                                                                                                         //
//    ....                                      ....,cooooooodxkxxddc. ..  ...'..                                                                                                                                          //
//    .                                          ...':clccclddxxxdo:.                                                                                                                                                      //
//                                               ..',;:::clodxxxxxl.                                                                                                                                                       //
//                                      .,.      ..,;:::lloodxxxxd'   .                                                                                                                                                    //
//                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PJS is ERC721Creator {
    constructor() ERC721Creator("Pedro J. Saavedra", "PJS") {}
}