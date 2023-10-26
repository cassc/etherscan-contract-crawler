// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Beary Odd Friends
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                    //
//                                                                                                                                                    //
//    ;;::::::ccccccccccclllllllllooooooooodddddddddddddddooooooooooddddddddddxxxxxkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxddddddddddddddoooooooooooooollll    //
//    ;;::::::cccccccccclllllllllooooooooodddddddddddddddddooooooooddddddddxxxxxxxkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxddddddddddddddoooooooooooooolll    //
//    ;::::::ccccccccccllllllllloooooooooddddddddddddddddddddoooodddddddddxxxxxxkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxdddddddddddddoooooooooooooool    //
//    ;::::::cccccccccllllllllloooooooooddddddddddddddddddddddodddddddddxxxxxxxkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxddddddddddddddooooooooooooooo    //
//    ;:::::cccccccclllllllllloooooooooddddddddddddddddddddddddddddddxxxxxxxxxxkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxdddddddddddddddooooooooooooo    //
//    ;:::::ccccccccllllllllloooooooodddddddddddddddddddddddddddddddxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxdddddddddddddddoooooooooooo    //
//    ;::::ccccccccllllllllloooooooodddddddddddddddddddddddddddddddxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxdddddddddddddddooooooooooo    //
//    ::::cccccccclllllllllooooooooddddddddddxxxxdddddddddxdddddddxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxdddddddddddddddoooooooooo    //
//    :::cccccccclllllllllooooooooddddddddddxxxxxxxxdddddxxxxddddxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxddddddddddddddddoooooooo    //
//    :::ccccccclllllllloooooooodddddddddddxxxxxxxxxxdddxxxxxxddxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxdddddddddddddddddooooooo    //
//    ::ccccccclllllllloooooooodddddddddddxxxxxxxxxxxxdxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxddddddddddddddddddoooooo    //
//    ::ccccccllllllllooooooooddddddddddxxxxxxxxxxxxxxxxxxxxxdddxxxxxxxxxkkkkkkkkkkkkkkkkkkkkxdxkkkkkkkxxxxxxxxxxxxxxxxxxxdddddddddddddddddddooooo    //
//    :cccccclllllllloooooooooddddddddddxxxddxxxxxxxxxxxxxxxxdcoxxxxxxxxxkkkkkkkkkkkkkkkkkkkkocdkkkkkkkxxxxxxxxxxxxxxxxxxxddddddddddddddddddddoooo    //
//    :ccccccllllllloooooooooddddddddddxxxxdlcdxxxxxxxxxxxxxxd:;oxxxxxxxxkkkkkkkkkkkkkkkkkkkd;:xkkkkkkxkxxxxxxxxxxxxxxxxxdddddddddddddddddddddoooo    //
//    ccccccllllllllooooooooodddddddddxxxxxxl,:dxxxxxxxxxxxxxd:';oddxxxxxxkkkkkkkkkkkkkkkkkd:':xkkxxxxxxxkxxxxxxxxxxxxxdddddddddddddddddddddddoooo    //
//    ccccccllllllllloooooooodddddddddxxxxxxd,.;oxxxxxxxxxxxxx:..;odddxxxxxkkkkkkkkkkkkkkxo;'.cxxxxxxxxxxxclxxxxxxxxxxdddddddddodddddddddddooooooo    //
//    cccccllllllllccccclloooodddddddddxxxxxxc..,cdxxxxxxxxxxxc..'cdxxxxxxxxkkkkkkkkkkxxkd:'..ckxxxxxxxxo;'lxxxxxxxxdolcc::;;;;;;::llooooooooooooo    //
//    ccccccc:;,'.......''',,;clodddddddxxxxxo. .':oxxxxxxxddxo. .,lkO0OOOOOOOOOOOkkkkxxd:'. .oxxxxxxxdl;.'oxxxxddoc;'...............';:cloooooooo    //
//    ccc:;'... ......'''.......;lodddddddxddd:  ..;oxxxxxxkOOx,..;ckKXXXKXXXNNNNXXXK0Oxc,'. ,dxxxxxxdc,..'dxxdddc'.. ...'',,,'......  ..,cloooooo    //
//    c:;..   .......'',,''...   .;lddddddddddo'   .;dkOO0KKKXKOxk0KXXKXXNNWWWWWWNNNNNXKOxo:;lkOOOkkdc,.. ;ddddl,.  .....',,,,'........   .;cooooo    //
//    :,.    .........'''''.....  .'ldddddddddo,..,cx0KXXNNNXNNNXXXNNXXXNNWWWWWWWWWWWWNNNNXXKKKKKXKK0ko:'.cdddl'    ......'''.'''''.....   .,coooo    //
//    ,.    ......''............    'lddddxkOOxdxO0XNNNKkkKNNNXXXKKKXXNNNWWWWWWWWWWWWWWWNNNNNNNXXXXXK0KK0kkxdc.     ..........'''''.....    .;cloo    //
//    .     .....''''..........      ,ldk0KXNXNNNNNWWWXc..oXNNXKxookKXNNNWWWWWWWWWWWWWWWNNNNWNNNXXXXOOKXXXKKOd;.      .........''''.....     .;clo    //
//         ......'''........ .       ;x0KXNNWNNKxoxKWWNklo0NWWWk...,ONNWWNXNWWWWWWWWWWWWWNNNNNNNXXXXXXXXNNXXXK0x:.         ..............     .;lo    //
//         .............           .lOXXXXNWWWW0;.;OWWWWWWWWWWWKc',dXWWWWXOKWWWWNNNWWWWNNNNNNNXXKKKKKKXXXNXXXKK0Ox:.         ............      ':l    //
//         .............         .:x0XXNNNNWWWWNKOKNWNWWWWWWWWWNXKXNNNWWWWWWWNNNNNNNNXO0XXXXXX000000dd0KXXXK0kkkxOOd,           ........       .;c    //
//             .....            .lk0XXXXNNNWWNNNNNNNNNNNNNNNNWNNXXNNNNNNNWWWNNNXXXXXXK00KKKKK0OkdldkxxkO0K00OkxkOOOkd:.                        .;c    //
//                             ,dk0KXXXXXXNOdOXXXKKKKKXXXXXXXNNXXXXXNNNXNNNNNNXXXKO0K000OkOkxxddollooooldkkxxxxkkkkkxdc.                       ':l    //
//                            ,dkO00KKKKKK0l':c:;;;;;:lodk0KKKXXXXXXXXXXXNNXXXXKK0kkOkkxddxolllc::;:::cclooollldoldkkdc,.                     .;cl    //
//                           ,oxOOOO00Oxo:'.            ..,cdk0koxKXXXXXXXXXKKK0O00Okxdoollc;,'.........',:ccclodxkkkd;..                    .,clo    //
//                          'lxkOkkl:c;.                    .,c;.;kKKKXKKKKKKKKkxkdoddol:;'.';codxxxxdoc;,...';clodxxxo:;'                   'cllo    //
//    .                    .cdxkkkxc.       .';:cllcc;,..     ..;dO0KKKKK0kOKK0Okxolol:,.':d0XNNNNXNNNXXKOxl,...;:looddol:.                .,clloo    //
//    '.                  .,ldxxxo,.     .;dO0XXNNNXXXKOxc'.    .,oO0000kkOO00Okxdolc,.'cOXNWWWWWWNNNWWWNNK0ko,...,:llooc:'             ..,:cloooo    //
//    :;'.                .,loccc.     .cxKNNXXXXXXXWWWWNXOo,.    .cddxOddkOOOkxdol:'.:xKNNNWNXK0KK00KK00KXK0ko:. .';cccc:'.        ..',:clloooooo    //
//    cc::,..             .;ll:,.    .;d0KKKKXXXXXXKKKKNWWNXkc.    .;lxOxoxkkkxxol;..cOXNXNX000KNWMWWMWNK0Okkkdl;. .';::;,......'',:cclllooooooooo    //
//    cccccc:;,...       .;clol'    .;dOO0KNWWNXXNWMMWX00XNXKkc.    'lkkkkkxxxdol:..:xKKKX0x0NWNOdlllllx0XXOolol:'. ..,;,',',collllloooooooooooooo    //
//    cccclllcccc::;;;,,.';:;;,     'lxxkXXOo:'..';lONWWKk0XK0d;.   .;dkxxxxddol:'.'oO00KkoONKx,..,cc;. .:dxd:;:;'.  .',,',',loooooooooooooooooooo    //
//    cccclllllllllllloo;':c:'.    .;lloOkc.        .:OXNOok0Oxc.    'oxxxxdddoc,..,okkkxcoOk:.    ..     .;c:'','.  ...',,..coooooooooooooooooooo    //
//    ccccclllllllllllol,.,cl:.    .;c:ld:.           'x0Olcxxdc.    .lxxdddool:. .;odddc;od:.             .,,.....   .',,,'':oooooooooooooooooool    //
//    ccccclllllllllllol,.;cc,.    .,;;cl,             :xxc;lol;.    .ccldooolc,.  ':cll;,cl;              .''.....   .',,''.:ooooooolllllllooolll    //
//    ccccccllllllllllol,':cl;.     .'',cc.           .cdl:,cc:'.    ,dxddooll:,.  .,;:c,.;c:.             ';.  ..    .'','..:ooooolllllllllllllll    //
//    ccccccccllllllllll,':cll'     ....'cc. .'..    .:l;,',:;'.    .:xkxdollc;'..  .',;,..';:'    ....   ,c'        ...','..:ooolllllllllllllllll    //
//    ccccccccclllllllll,';c:;;.     ... .;c:,;;,'.,:c;....,,'.     .okkxxdoolc:;..  ...'....';;,......';c:.         ...'''..:olllllllllllllllllll    //
//    ccccccccccllllllll,.,:ccl;.          .,:::::::'.........     .cdxxxxxdddc::,.    ....    .,:::::::;.           ..''...'colllllllllllllllllll    //
//    :cccccccccclllllll,.,:clol,                       ...       .'.'cdxxxxxdl::;,..              ...              ...'','.'colllllllllllllllllll    //
//    :cccccccccccclllll;..;cllll,.                   .          .c:.'cdxxxxxxdolc:,..                             ...''.'..'cllllllllllllllllllll    //
//    ::ccccccccccccclll;..,:loolc,.                           .;oxxxxxkkxkxxxxxdoc:,'..                          ..'',,,'..,lllllllllllllllllcccc    //
//    ::cccccccccccccccl:...;llooo:;,.                        .cdxkkkkkkkkkxddxxxdc;::;,...                     ....''','...;llllllllllllccccccccc    //
//    :::cccccccccccccccc'..,:cloooool;..                 .';',oxxxxxkkxxxdc:cdxddooolc::;'...                 ....',''''...:lcccccccccccccccccccc    //
//    ::::::ccccccccccccc,...,;;;coooolc'  ....    .....;ldddddxdxxxkkkkkxllddxdolodddoolc:;'...            ...'''.',,'... 'cccccccccccccccccccccc    //
//    ::::::::::ccccccccc:. ..',;cllollc'.'clc;.  .:ll;;dxxkkkkxxxxkkkxxxdxxxxddoloc;codoolc;''.............',,,;''''...  .:cccccccccccccccccccccc    //
//    ::::::::::::cccccccc;.  .',;ccccccccclll;. .,ldddxxxxxxxxxxxkkkkxxxdxxxxddddd:':oooool;,:;,,''...''',,;;;;;;,'...  .,ccccccccccccccccccccccc    //
//    ::::::::::::::ccccccc,   ..'.';::cccccccc::cloddddddxxxxxxxxxxxxxdddxxxxdddddoddooooolllcc::::;,,;;;;:::;;,''..    ,ccccccccccccccccccccccc:    //
//    ;::::::::::::::::cccc:'       .';;;,';:::c::clooddddddddddxdddoodoloodddoooooooooooollccccc:::::;;;;::;;;,'...    ':c:cc:c::::::::::::::::::    //
//    ;;;::::::::::::::::::::,.     ..'',,,;;;;;,';ccllooooddddddddooooolloolooooolllllllllcc::::;;;;;;;;;;,,''...    .,::::::::::::::::::::::::::    //
//    ;;;;::::::::::::::::::::;.     ....''',,,,;;;;::cclllooooollllc;,::::;;,;clc;:c:;::cc::;;;;,,,,,,,'''....     .';:::::::::::::::::::::::::::    //
//    ;;;;;;::::::::::::::::::::,..     ......''''',,'.,::cc:;;:cc:c;.        .:c:;;:;,,;;;,,,,,'''........       .';:::::::::::::::::::::::::::::    //
//    ;;;;;;;;;;::::::::::::::::::;'.         ..........,,,;,..,;;;,'..     ..';;;;;;;;,,''''........          ..,;::;:::::::::::::::::::::::::;;;    //
//    ;;;;;;;;;;;;;;::::::::::::::::;,'...          ....................   ......'''...........           ...',;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ,,;;;;;;;;;;;;;;;;:::::::;:;;;;;;;;,'...                                                        ..',,,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,..                                                        .,,,,,,,,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ,,,,,,,;;;;;;;;;;;;;;;;;;;;;;;;;,,,,'.                                                           .',',,,,,,,,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ,,,,,,,,,,,;;;;;;;;;;;;;;;;,,,,,,,,'.                                                             .''''',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,;;;;,,,,,,,,,,,,,,.                          BEARY ODD FRIENDS                     .''''''',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.                             LSDGB.COM                           .'''''''''',,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ''',,,,,,,,,,,,,,,,,,,,,,,,,,''''.                                                                   ...'''''''''''',,,,,,,,,,,,,,,,,,,,,,,,    //
//    '''''',,,,,,,,,,,,,,,,,'''''''''.                                                 ..                  .....'''''''''''''''''',,,,,,''',,,,,,    //
//    '''''''''''''''''''''''''''''''.....      .'',,,,,'..              ........      .;,,,,,,,,,,.        ........''''''''''''''''''''''''''''',    //
//    ''''''''''''''''''''''''''''''.......     ,xkkkkkkkxoc;.        ..''''''''''.    '::::::::::c'      .  ...........''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''.........''..     .okkkkkkkkkkxdc.     .,;;,,,''',;;;'   ,cccc,',',,,.     ....................'''''''''''''''''''''    //
//    ......'''''''''''''.............,,'.       :xkkxl;;lxkkkxl.   .;:::;,.  .,;::;. .:llo;.            ........................'''''''''''''''''    //
//    ...............................,;,'.       .oxxxc.  ;xkkkd'  .;cccc;'''..,ccc:, .cooo;             ..............................'''''''''''    //
//    ..............................':;;'.       .:ddxo.  'dxxkd'  .:cclc;,::;';llll:..lddd;             ..''..............................'''''''    //
//    ..............................;::;'.        'oddd:';lodxd;.  'clll:,'...,:loooc..odddl;,;;,,'      ..,,'. ..............................''''    //
//    ..............................,;:;.         .:ollllloooc'    'clll:,,'.';cooool',dxddxdddddd:      ..,,'....................................    //
//    .............................,;::;.          'ccccclllc:;,.  'clll:,;::::cooool,;dxxdollllcc'      .',;,.. .................................    //
//    .............................,:c:,.          .,::::;,,;::c:,..clll:,;:;:;cooodl';dxxl....           ';:;,.  ................................    //
//    .............................,:c:,.           .,;:;.   .,:::'.;lllc,,::;;coooo;.;ddxc.              .;::;.  ................................    //
//    .............................;:c:,.            ',;;,.   .;;:,..cllc,,;:;,coool. ;dddc.              .;:c:'  ................................    //
//    ..........................  .;ccc:.            .',,,.  ..,;;,..,ccl;....,looo,  ;ddd:               .;:c:'        ..........................    //
//    ..........................  .,:cc:'.            .''''..',,,,.. .,clc;'';cloc'   ;ddd:               .;:c:.          ........................    //
//    ..........................  .';:::::,,'.        ..''''.''...     .';;:::;,'.    ,ccc'               .;cc:'.........  .  ....................    //
//                    .           .';;cclcccc:;.       .....                                              .:lc:;;;:cc:;,'..      .................    //
//                              ...'',;;;;:::;;;..                                                       .;c:;;;;:c:;,,'....         .............    //
//                              ......,,''''''''...                                                   ...';,,;;,,;;,'......                 ......    //
//                                ..................                                              ...'',,'''''''........                              //
//                                  ........ .....                                           ....'''''''.............                                 //
//                                    ....            .....                              ...'',,'''''...........                                      //
//      .................                              ...'...                        ...'''',,,,'''''..........               ...................    //
//    ......................                            .'..''....                  ........','..'','..........                ...................    //
//    ......................                            ...'''..'..                 .......'',,',,''..   ..                    ...''''''''''''''''    //
//    ....................                              ..''''....                  .........''''''...                        ..''''''''''''''''''    //
//    ..'''''...........                                 ......                      ................                         .'''''''''''''''''''    //
//    .'''''''..........                                 ...                               ......                            ..'',,,''''''''',,,,,    //
//    .''''''''''.........                                                                                                   .'',,,,,''''''',,,,;;    //
//    ..'''''''''''''.........                                                                                              .',,,,,,;;;;;,,,;;;;::    //
//    ..'''''''',,,,,''''''....                                     ...............                                        .'',,;;;;::::::::::::cc    //
//    ...'''''',,,,,,,,,,,''''...                                ..,,;;:::::::::::;;,'...                                  ...',;;;::::ccc::cccccc    //
//    ....'''''',,,,,,,,,,'''....                             .',;:::cccccccccccccccccc:;;'..                                ...',;;::::cccccccccc    //
//    .....'''''',,,,,,,'''....                            ..';::ccccccclllllllllllllllccccc:;,'..                             ...',;;::::cccccccc    //
//    .......'''''',,''''....                            ..';::ccccclllllllllllllllllllllllccccc:;,'..                           ..'',;;:::ccccccc    //
//    ........''''''''''....                           ..',;:cccccccccccccccccllllllllllllllllcccccc:;,'...                     ...'',;;;:::::::::    //
//    ..........''''''''....                        ...',;:::ccccccccccccccccccccccccccccccccccccccccccc::;;,''.................'',,;;;:::::::::::    //
//    ............''''''.........          .......'',,;;:::::cccccccc:::::ccccccccccccccccccccccccccccccccc:::::::;;;;;;;;;;;;;;;;;:::::::::::::::    //
//    ...............''''''''...........'''''',,,,;;;;;:::::::::::::::::::::::::::::::::::::cccccccccccccccc:::::::::::::::::;::::::::::::;;;;;;;;    //
//    ................'''''''''''''''''',,,,,,,,;;;;;;;;;:::::::::::::::::::::::::::::::::::::::::::::::::::                                          //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BOF is ERC721Creator {
    constructor() ERC721Creator("Beary Odd Friends", "BOF") {}
}