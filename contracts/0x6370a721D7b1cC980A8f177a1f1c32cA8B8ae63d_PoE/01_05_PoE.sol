// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Permutation of Ego
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    kkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxxddddddddddddddddddddooooooooooooooooollllll    //
//    kkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxddddddddddddddddddoooooooooooooooo    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxddddddddddddddddooooooooooo    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOO0OO00000000000000000000OO000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxdddddddddddddddoooooo    //
//    OOOOOOOOOOOO000000000000000000000000000000000000000000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxddddddddddddddo    //
//    OOOOOOO0000000000000000000000000000000000000000000000000000000000000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxddddddddddd    //
//    0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000OOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxddddddd    //
//    0000000000000000000000000000000000KKKKKKKKKKKKKKKKKKKKKKKKKK000000000000000000000000000000000000000OOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkxxxxxxxxxxxxdddd    //
//    0000000000000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0000000000000000000000000000000OOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkxxxxxxxxxxxxxd    //
//    0000000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0000000000000000000000000OOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkxxxxxxxxxxx    //
//    000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00000000000000000000000OOOOOOOOOOOOOOOkkkkkkkkkkkkkkxxxxxxxx    //
//    000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00000000000000000000OOOOOOOOOOOOOOOkkkkkkkkkkkkkxxxxxx    //
//    000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00000000000000000000OOOOOOOOOOOOOOkkkkkkkkkkkkkxxxx    //
//    0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXKXXKKKKKKKKKKKKKKKKKKKKKKKK00OkxxdoollllllllllooddxkO000000000000000OOOOOOOOOOOOOOOkkkkkkkkkkkkxx    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKXKKKKKOOkdl:;,''',,;;::ccc:;,''.....',;:codkO00000000000OOOOOOOOOOOOOkkkkkkkkkkkkk    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0xc'..  ...;ldxxkkkkkkxxdolcc:::;;,'....';coxkO00000000OOOOOOOOOOOOOkkkkkkkkkkk    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXOl'.    .;c:clllllloddddddddddolllooddol:;'..',:ldkO00000OOOOOOOOOOOOOOkkkkkkkkk    //
//    KKKKKKKKKKKKKKKKKKKKXXKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKxc;'.   .,;,'';:cllllcccclodkOkxollokOOOOOd,......':okO000OOOOOOOOOOOOOOkkkkkkkk    //
//    KKKKKKKKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0ocl:'..     ..',,''''''',:loxkkxkkddxO000Ol.       ..,cdkO0OOOOOOOOOOOOOOkkkkkkk    //
//    KKKKKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXO:.''''''.     ...........;ccodxdxkOkkkkOOd;.         ...;lxO0OOOOOOOOOOOOOkkkkkk    //
//    KKKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0c..,:cccc;.    .'','''...,;cloddodkOOOkkd:.            ...,cxOOOOOOOOOOOOOOkkkkk    //
//    KKKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKo..':llodo:.   ..,;;;;,,;;;:cloooldxkkko;..              ...'cxOOOOOOOOOOOOOkkkk    //
//    KKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk' .;:cloool;.   .,;;;;;;:::cclclodxxxd;.                  ...,cxOOOOOOOOOOOkkkk    //
//    KKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0c..,;:cloddxd,   .';;;:::::::cccloddo:..                    ...,lkOOOOOOOOOkkkk    //
//    KKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx'..',;:coxxxo:.   ...,;;::::::cllll:...            ..       ....:dOOOOOOOOkkkk    //
//    KKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0c...',;:ldxdddc.      ....'',,;;::,........         ..         ..'lkOOOOOOkkkk    //
//    KKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXK00KKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'...',,:odddxxl'    ........................... ..    .         ..ckOOOOOkkkk    //
//    KKKKKXXXXXXXXXXXXXXXXXXXXXXXKOxl:,'';lOXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKl. ...';ldoddol:.    ....     ....  .    ...............         ..:xOOOOkkkk    //
//    KKKKKXXXXXXXXXXXXXXXXXXXXKOxl:,..     .cOXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0;. ..';:lllcc;,'.   .'..       ...      ...    .........         ..cxOOkkkkk    //
//    KKKKXXXXXXXXXXXXXXXXXXX0ko:,'..      ...'oKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXxc'..,::;;,,,'....  .c;..       ..            ..........         ...ckOkkkkk    //
//    KKKXXXXXXXXXXXXXXXXXK0koc;'.         .....:OXXXXXXXXXXXKkxxxdx0XXXXXXXXXXXKKo..;c:;,,''...     .c;.  .....       ... ...''.........        ...'okkkkkk    //
//    KKKKXXXXXXXXXXXXXXK0koc;'.             ....'dKXXXXXXXXKl.;lc,.;OXXXXXXXXXXXX0c.';:;,,,'.....    .cc..............'......'...........         ..;dkkkkk    //
//    KKKXXXXXXXXXXXXXX0koc:'.               .,,,',oKXXXXXXXO,.,:;,';xXXXXXXXXXXXXXO;..',,,'..''..     .cc.....';::::::;;'........  .......         ..cxOkkk    //
//    KKKKKKXXXXXXXXXKkl;,'.                 .,:::::o0XXXXXXKd'....:xKXXN0xkKXXXXXXXk'.';::,'',,.       .,'...,;cloollcc:;'...        ....           .,dOOOk    //
//    KKKKKKKKXXXXXKOo:'.                     .',;;;;lOXXXXXXX0xddxOXXXNXKO0XXXXXXXXXx'.;cc,.....         ...,:clodddooolc;'..                       ..ckOOO    //
//    KKKKKKKXXXXX0d:,,.                       ..,,,::ckXNXXNNXNNNNXXNNNXXXXXXXXXXXXXXo''cc,...            ..':clodxxddolc;,'..                      ..,dOOO    //
//    KKKKKKKKXKX0l,...                          ..,;:ccxXNXXXNXNNNNNNNNNXXXXNXXNXXXXNKl.,:,.           ..  ..,clooddddolc;,'..                        .lOOO    //
//    KKKKKKKKKKOc'...          ...''......         ..;::xKNNNNNXXNNNNNXNNXXNXXNNNNNXXN0c.',..         .''.   .,:lloooll:;,'...                        .:kOO    //
//    KKKKKKKKKOc'...        ..................       .':;oKNXXNNNXXXXXXXXXXXXNXXNNXXKXX0:.','..      ....'.   .';ccccc:;;,,''...                       ;kOO    //
//    KKKKKKKKOl,'..         ....................      .,;,lKNXXXXXXXXXXXXXXXXXXXXXX0xkXXO:.,;;;'.';,..',:od'   ..,;::::;;,,,'....                      ,xOO    //
//    KKKKKKK0o,'..           ......... .................,,.c0XXXXXXXXXXXXXXXXXXXXXXXxoOXXO;.,;,,,:l:',;:oxd;.   ..',;;;;,,''......                     ,xOO    //
//    KKKKKK0d;...          ...'.........  ......,::'........c0XXXXXXXXXXXXXXXXXNNXXXKxd0XXkccc'';;,..;;:::;:;.   ...'''''........                      ;xOO    //
//    0000KKk:'...     .  ...'''..............,cdk0Oxlcll,.  .:0XXXXXXXXXXXXXXXXXXXXXXKxdk0K0kl'.,,..';;;:::l:..   ...............                     .:kOO    //
//    00000Ol'...     .. ..,;:;,''.......''';lxO0KKXKOkddd;.  .:0XXXXXXXXXXXXXXXXXXXXXXKkoldOOo,''''',;;;;;:c:,'.  ..............       .   ..         .lkkk    //
//    00000d,...     .....';:::;,'..'',,,,;lxO00KKXXXX0kxdo;.  .:OXXXXXXXXXXXXXXXXXK00KXXK0kO0Kkol:;cc;;;;,;::;'.    ...........        .             .,dkkk    //
//    0000Ol...        ...,;;;,'.......'..'cxO0KKKXXXXX0kdol,. ..:OXXKkkOOOkkkkxddddc,ckKKOddxl,;c;,coc:;;,,,,,''.     .......                       ..:xkkk    //
//    OOOOx;...        ..',,............   .:xOKKKXXXK0kdl:;,.....;OXKOxolododddddk0d,.;dOOc'. 'l:..';:::;,,''..''.    .......                      ..,okkkk    //
//    OOOOo,...       ...''..   ......      .;dOKKK0Oxo;''.........:OKKKKKKKKKKK0OOkxl;;;lo'. .dKk, ..'cc;,,',''''..      ..                        ..cxkkxx    //
//    kOOkl'...       ...'.......''...       .'cdxdlc:'.  ..........:OKKKKKKKKKk:..,;'';cloc,.;OKKx, .:dxlc:;;;,'...                                .;dxxxxx    //
//    kkkkc....       ......''',,,'..         ..'''....    ..... ....:OKKKKKKkc...,xOo;...,:c,c0KK0k;'cdkkxkxoc:;,'..                              .'lxxxxxx    //
//    kkkx:....        .....'',,,,'...        .......             ....cO000Oo,';oxO0000ko;'';lk00000kc,:oxkOOOOxoc:,'.                            ..:dxxxxdd    //
//    xxxx:....        .......'',,,''...       ......               . .cOOl:cok0000OkkO00OOkO00000000kc,;ldxkO00Okxdl;.                           .:dxdddddd    //
//    xxxx:.                   ..,,,''.......     ...                  .:ocoOOOOdc:,,'':dOOOOOOOOOOOOOkl',coddxOkxxkkx:                          .;odddddddd    //
//    dddd:.                   ..'',,''.........  ...               ... .:kOOOOd'.......,dOOOOOOkxoc;;:c:'';:clodxxxddl.                        .:odddddoooo    //
//    ddddl.                    .....................           .    .....ckkOko,..',,'.,dkkkkkd;..'..  .....,::oxxolll,                       .codooooooooo    //
//    odddo,..                      ...',,'.........     .       .    .....cxkkxl:,',,,:oxkkkkd,  .'.......'..'',::cc::,.                    .,looooooooooll    //
//    ooooo:..                       ..',,'.........   ....            .,,..lxxxxxxdoodxxxxxxxl. ......'...::...',,;;;,'.                   .;loooooolllllll    //
//    oooool,.                        ..''.........    ..'..           .;c;..lxxxxxxxxxxxxxxxxo,.....;:::,;ldl'...'',,'...                .,clloolllllllllll    //
//    llllol:.                        ............     .....           .;llc.'lddddddddddddddddl,......';codddo;...''.....              .':llllllllllllllccc    //
//    llllllc,.                         ........      .........    .....,clo:.,lddddddddddddddddoc:;,',:coooooooc'. ......            .':llllllllllccccccccc    //
//    lllllll:'.                         .....        ....',::,'........,:;,'..,oddooooooooooooooooooooooooooooool:.   ....       ...,:lllllllcccccccccccccc    //
//    ccclllll:.                                      ..'',;ccc:;,'.',,,,,.    .;looooooooooooooooooooooooooollllllc;....'.      .,:cllllccccccccccccccccc::    //
//    ccccccccc;.                                      .',;:clllc;,'',,,,'.     .';oooooollllllllllllllllllllllllllllc;,'..  ..';:clccccccccccccccccccc:::::    //
//    cccccccccc;.            ..                        .';;:cllc:'...''...       .:lllllllllllllllllllllllllllllllllllcc:;;;:cccccccccccccccccccc::::::::::    //
//    ccccccccccc;.                                      ..',;:::;'...'........    'cllllllllllllllllllllllllcccccccccccccccccccccccccccccccccc:::::::::::::    //
//    cccccccccccc:'                                        ..,,,,,'..'... ..       ,clllllllllllllccccccccccccccccccccccccccccccccccccccccc::::::::::::::::    //
//    cccccccccccccc,.                                      ....''''.....           .;lllllccccccccccccccccccccccccccccccccccccccccccccc::::::::::::::::::::    //
//    ccccccccccccccc:'.                                         .....               .:lccccccccccccccccccccccccccccccccccccccccccccc:::::::::::::::::::::::    //
//    ccccccccccccccccc;..                                                            ,ccccccccccccccccccccccccccccccccccccccccccccc::::::::::::::::::::::::    //
//    ccccccccccccccccccc;..                                                          .:ccccccccccccccccccccccccccccccccccccccccccccc:::::::::::::::::::::::    //
//    ccccccccccccccccccccc;'.                                                         'ccccccccccccccccccccccccccccccccccccccccccccccc:::::::::::::::::::::    //
//    ccccccccccccccccccccccc:'.                                                       .:lcccccccccccccccccccccccccccccccccccccccccccccccc::::::::::::::::::    //
//    ccccccccccccccccccccccclcc;..                                                    .;llllcccccccccccccccccccccccccccccccccccccccccccccc:::::::::::::::::    //
//    cccccccccccccccccccclclllllcc;'.                                                 .:llllllllccccccccccccccccccccccccccccccccccccccccccccc::::::::::::::    //
//    cccccccccclllllllllllllllllllllc:,'.                                            .;lllllllllllllllllllccccccccccccccccccccccccccccccccccccccc::::::::::    //
//    llllllllllllllllllllllllllllllllllll:;'...                                ....,:cllllllllllllllllllllllllllllllllcccccccccccccccccccccccccccccccccc:::    //
//    cccccccccccccccccccccccccccccccccccccccc:;,'....                    ....',;::ccccccccccccccccccccc::::::::::::::::::::::::::::::::::::::::::::::::;;;;    //
//    ..................................................                 ...................................................................................    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PoE is ERC721Creator {
    constructor() ERC721Creator("Permutation of Ego", "PoE") {}
}