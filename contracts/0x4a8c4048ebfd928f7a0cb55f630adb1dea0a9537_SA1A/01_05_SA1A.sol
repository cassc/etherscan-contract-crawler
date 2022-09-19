// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Scrawlzy Abstarct 1a
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    ;,,,,,;;;;;;;;;;;;::::::::::::::::::::::::::::;;;;;,,,,,,,''''lKXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNXkONNXXK0Okxdool    //
//    ,,,,,,,,,,;;;;;;;;::::::::::::::::::::::::;;;;;;;,,,,,,,,''''.c0XXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXOkXNXXKK0Oxdolc    //
//    ,,,,,,,,,;;;;;;;;:::::::::::::::::::::::::;;;;;;,,,,,,,,'''''.:OK00000000KKKKXXNNNNNNNNNNNNNNNNNNNNNNNNNN0kKNXXKK0Okdolc    //
//    ,,,,,,,,;;;;;;;;;;:::::::::::::::::::::::;;;;;;;,,,,,,,''',;:cokkkkO0KKKXXXXXXKKXXXXNNNNNNNNNNNNNNNNNNNNNKx0NNXXK0Okxoll    //
//    ;,,,,;;;;;;;;;;::::::::::::::::::::::::;;;;;;;;;,,,,,'';:ldkkOOOOO00KKKXXNNNNWNNNXKKKXNNNNNNNNNNNNNNNNNNNXkONNXXKK0kxdol    //
//    ;,,;,;;;;;;;;;;::::::::::::::::::::::::;;;;;;;;,,,,,;:ldxxkkkkOOOOO00KKKXNNWWWWWWWWWNNNNNNNNNNNNNNNNNNNNNXkkXNXXKK0Oxdol    //
//    ;,,,,;;;;;;;;:::::::::::::::::::::::::;;;;;;;;;;,,;cooddddxxxxkOOOOO00KKXNWWWWWMMMMMMMWWWNNNNWNNNNNNNNNNNNOkKNNXXK0Okdol    //
//    ;,,;;;;;;;;;::::::::::::::::::::::::;;;;;;;;;;,,;clollloddxxxxkOO000000KXNWWWWWWWMMMMMMMMMWWWNNWWWWWNNNNNNKkKNNXXKK0kxdo    //
//    ;,;;;;;;;;;::::::::::::::::::::::::;;;;;;;;;;,;:ccccccllodxxxxxkOO00000KXNNNWWWWWWWWMMMMMMMMMWWWWWWWNWWNNWXk0NNXXKK0Oxdo    //
//    ;;;;;;;;;;;::::::::::::::::::::::;;;;;;;;;;;,,;::::::clllodxxxxkOO000K0KXXXNNNNNWWWWWWMMMMMMMMWWWWWWWWNNNWNOONNNXXK0Okdo    //
//    ;;;;;;;;;;;;::::::::::::::::::::;;;;;;;;;;;,,,;;;:c::ccllodddxkkkOO0KKKKXXXXXNNNNNNNWWWWWWMMMMWWNNWWWWWWNNN0kXWNXXKK0kxd    //
//    ;;;;;;;;;:::::::::::::::::::::::;;;;;;;;;;;,'''',:c::cccloooddxkkOO000KKKKKXXXXXNNNNNNNNNNWWWWWWNNWWWWWWNNWKkKWNXXXK0Oxd    //
//    ;;;;;;;;;::::::::::::::::::::::;;;;;;;;;;;,''''',:cccclllloooddxkkOO0000KKKKKKXXXXNXNXXXNNNNWWWWNNWWWWWWNNWXk0NNXXXK0Okd    //
//    ;;;;;;;;;::::::::::::::::::::;;;;;;;;;;;;,'.'''',;:clllllloooddxkOO0KK000KKKKKKXXXNNXXXXXNNNNWWWWWWWWWWWNNWNOONWNXXKK0kx    //
//    ;;;;;;:::::::::::::::::::::::;;;;;;;;;;;;'...'''',;:cloooodddddxkOOO0KK000KKKKKXXNNNNNNNNNNNNNNNNNWWWWWWNNWN0kXWNXXXK0Ox    //
//    ;;;;;;;;;:::::::::::::::::;;;;;;;;;;;;,,,'...'''',;:ccloodddxxxkOO000KKKKKKKKKKKXNNNNWWWWWWNNNNNNNNNWWWWWNWWKkKWNNXXK0Ok    //
//    ;;;;;;;;;:::::::::::::::::;;;;;;;;;;;,,;,....','',;:::clloodddddxkOOO0KKKK000KKKKXXXXNNNNNNNNNNNNNNNNWWWWWWWKk0WNNXXKK0k    //
//    ;;;;;;;;;;::;:::::::::::;;;;;;;;;;;;;,,;,.....',,,;::cccllloddoodxkkkO0KK0OO00000KKKKXXXXNNNNWNNNNNNNWWWWWWWXkONWNNXXK0O    //
//    :;;;;;;;;;;;;:::::;;:::;;;;;;;;;;;;;,,,;'......'',::ccclooooddddddxxxkO00kdxkOOOOO00KXXXXXNNWWWWWNNXNWWWWWWWNOOXWNNXXK0O    //
//    :;;;;;;;;;::;;;:::;;;;;;;;;;;;;;;;;;,,,,'......'',,,,,;;::::::ccclllloxOOdoxxxxddxxxkkOOOOOO0KKNNNXXNWWWWWNWW0kXWNNNXXK0    //
//    :;;;;;;;;::;;;;;;;;;;;;;;;;;;;;;;,,,,,,,'...........'',;;,'''''''',,;:cxOxdkkxoc::::::;:loxO00Ok0XXXNWWWWWWWWKk0WWNNXXK0    //
//    :;;;;;;;;;:;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,...........',:::::;;;,,,,,,,,;d0kk00Oo,',,;;;codkO00KKOxOKXNWWWWWWWWXkONWNNXXK0    //
//    :;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,'.............',;:::codolc:::;;;,',lkkkO0Oo;,;;;:clodxxxxxO0OkO0OOKNNWWWWNOkXWNNXXXK    //
//    :;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,......   .''''''''''.',;,,,,,',,'..:dxkOOkc,;;;,;::::ccllllxOO00x;'';OWWWWKkKWNNXXXK    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,'....... .,,''.........'',::;,,''..lO00XNWx'';;,,'''.',;;cloxOOOd'..;0WWWWXk0WWNNXXK    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,'.........,;,,''',;:;;:odddolc;'...cxO0KNNk;;oollllccloddk00OOOOl';kNWWWWWNOONWNNXXK    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,'........';::;;;;;:clodxkxdoc;,'...;lk0XNXKdlxxdddxkkOO00KXXK00Ol;l0WWWWWWW0kNWNNXXX    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,,'..'.....;;;:::::::cclllllc:,'...';lkKNNXKOxdxxdoooddxkOOO0OOOOkdxXWWWWWWWKkKWNNNXX    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,'........,;::cllooddddooooc:,'''',:okKNWNXK0kkO0OOkkkOO000000KXKOKWWWWWWWWXk0WWNNXX    //
//    ;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,'''.........';::::cloodddddol:;,'''.':ox0NWNX000OO000KK00000OO00KK0KNWWWWWWWWNOONWNNXX    //
//    ;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,''''.........,;:ccloodxxxxxdoc:,'.'.':okKNNNXKK0O0KKKKKKKKKKKKKKKK0KNWWWWWWWWWOkNWNNXX    //
//    ;;;;;;;;;,,,;;,,,,,,,,,,,,,,,,,'''''''..........,:cloddxxxxxxdol:,',,'.;ok0K000KXX0O0KKKKKXXXKKKKKK0KNWWWWWWWWWWKkXWNNNX    //
//    ;;;,;;;;;;;,;;,,,,,,,,,,,,,,,''''''''''.........',:coddxxxxxxxdl:,''....:odxxkdox0KOO00KKKKKK000KK00XWWWWWWWWWWWXk0WWNNX    //
//    ;,,;;;,,,,,,,,,,,,,,,,,,,,,''''''''''''''........';:loodxxxxddol:'......':cldl'..:x0OkO00KK000000000NWWWWWWWWWWWNkONWNNN    //
//    ;,,,,,,,,,,,,,,,,,,,,,,,,,''''''''''''...........',;:looddddoolc:'.......',:lol:;o0KK0kkO0000000000KNWWWWWWWWWWWW0kNWNNN    //
//    ;,,,,,,,,,,,,,,,,,,,,,'''''''''''''''............',;:coodooolllc;,''...'',;cdkkkk0XXXK0OkkOOOO00000KNWWWWWWWWWWWWKxKWWNN    //
//    ,,,,,,,,,,,,,,,,,'''''''''''''''''''..............';:looooolllc::;;,,,;:ccldxkO0KKKXXKKK0kxkkOOOOkOKWWWWWWWWWWWWWXx0WWNN    //
//    ,,,,,,,,,,,,,,'''''''''''''''''''..................,loollllcc::c:::::cloddddxkO000KKKKK000OkxkOOOkkKWWWWWWWWWWWWWXkONWNN    //
//    ,,,,,,,,,'''''''''''''''''''''''...................;oddlccc:;;;:c::::cldkOkxkO00000000OOOOOOkkOOOkOXWWWWWWWWWWWWWNkxXWNN    //
//    ,,,,,,'''''''''''''''''''''........................;oxxollc;'......''',;coxddoooodxxxoloxkOOOkOOkk0NWWWWWWWWWWWWWW0xKWWN    //
//    ,,',,'''''''''''''''''''...........................,ldxxdll:;;'.....'',,'',;;;:::::clc:cdkOOOOkkkkKWWWWWWWWWWWWWWWKx0WWN    //
//    ,'''''''''''''''''''.'..............................;oxxdolllc;,,;;:cclooddxkkkkkkkkkOkxxkkOOkkkxONWWWWWWWWWWWWWWWXxOWWN    //
//    '''''''''''''..'....................................':oddoolllc:;,,,;:clooddxxxxxxxkOOOkkkkOkkkkONWWWWWWWWWWWWWWWWNkkNWN    //
//    '''''''''''....................................  ....':lllllcclccc:;;;;;;;::cclodxO000OOOOkkkkkOXWWWWWWWWWWWWWWWWWW0xKWW    //
//    ''.''..''.....................................    ....,::clcccllloolllllcllloodkOO0000OOOOxdxxONWWWWWWWWWWWWWWWWWWWKx0WW    //
//    '............................................. ..  ....';:cccllloddodddxkkOOO000000KK00OOkxdxkXWWWWWWWWWWWWWWWWWWWWXkONW    //
//    '.................................................  ....',:loodddddddddxkkOO00KKKKKKKK0OOkdokXWWWWWWWWWWWWWWWWWWWWWNOkXW    //
//    .................................................... .....,coodddodddddxkxkkkO000KKKKKKOkocl0WWWWWWWWWWWWWWWWWWWWWWW0xKW    //
//    ...........................................................,:clloloooodxxkxxxkOO000KKKKxl:cxXWWWWWWWWWWWWWWWWWWWWWWWKx0W    //
//    .............................................................',;ccloolodxxxxxkkO000KK0d::odkNWWWWWWWWWWWWWWWWWWWWWWWXkON    //
//    ................................................................';clolloodddddxxxxkkdlcldxxONWWWWWWWWWWWWWWWWWWWWWWWNOkX    //
//    ...................................................'''.............',;:::cccllc::::;:ldxxxxONWWWWWWWWWWWWWWWWWWWWWWWW0xK    //
//    ..................................................''''''.......................'';:ldxxkkxxONWWWWWWWWWWWWWWWWWWWWWWWWKx0    //
//    .............................................'''''','',''.......''''''''',,;;:lloodxxkkkxxkOXWWWWWWWWWWWWWWWWWWWWWWWWXkO    //
//    ...............................   .',,,''''',,,,,,,,,;,,,'.....',,;::cccllooddddddxxkkkxxxOxco0NWWWWWWWWWWWWWWWWWWWWWNOk    //
//    ............................       ..;;;;,,;;;;;;;;;;;;;;;,'....';:cloodddddddddddxkkkxxxk0O;..:ONWWWWWWWWWWWWWWWWWWWW0x    //
//    ..........................            .,:::cc:::::::::::cc:;,'..',;coddddddooooodxkkkkxkOOkc.....cx0NWWWWWWWWWWWWWWWWWKk    //
//    .......................                 ..':clccccccccccccc::;,,'',;ldxxddoooodxkkkkkkkxo:..........ckKNWWWWWWWWWWWWWWN0    //
//    ............   ....                         ..',;:cccllcloolcc:;;,'';coooodxxkkkkkxdl:,..  .........';:oxOXWWWWWWWWWWWWK    //
//    ...........     ... ..                           ..',;;:cooooolc::;,,,:clddxxdolc;'................,;;;;'':kXWWWWWWWNWWK    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SA1A is ERC721Creator {
    constructor() ERC721Creator("Scrawlzy Abstarct 1a", "SA1A") {}
}