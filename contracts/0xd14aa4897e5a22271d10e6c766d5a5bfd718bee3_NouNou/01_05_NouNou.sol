// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nouveau Nouveau
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    NWWWWWWNKkdx0XNNXXXXXXXXXKKKKKK0Okxxddddxxxxddddooollllcccccc:::::::;;;;;;;;;;;;;;,,;;::::::cccllooddxxxxxkOOKNNNNNNXNNNNWWWNNNNNXNNNNNNNNNXXXXXXXXNNN    //
//    WWWWWNNXOdclkKXXXXXXXKKKKKK0Okxddddxxxxdddooolllccc:::;;;;;;,,,,,,,,,,,,,,,,,,,,,,,'',,;;;;;:::::::cclloddxxxkO0KXXXNNNNNNNNNNNNNNWNXNNXXXXXXXKKXXXXNN    //
//    NNNNXXXXXKO0KXXXXXXKKKK0Okxddddddxdddooollccc:::;;;,,,,''''''''''''''.........''''''''',;;::::::;;;::::cloodddxxxkO00KNNNNNNXXNXXKXXNNNNNXXXKKKKKKXKKX    //
//    XNXXXXXXXXXXXXXXKKKK0Okxdddddddddoollcc:::;;;,,,''''....................................',;::::;;,;:::ccclloooddddddxkOKXNNNNX0kllx0KKKXNNXXXKKXXKKKKK    //
//    NXXXXXXXXXXXXKKKK0Okxdoddddddoollcc::;;;,,,'''...........................................',;;;;;;;;::ccclllooooolooddddxkKXXXX0xlldOKKXXXNNXXXXXKKKXXX    //
//    XXXXXXXXXXXKKKK0kxdoddddddoolcc::;;,,,'''..................                           ......',;;;;;:::cclllllollllccloddddk0KXXK0O0KKXXXXXXXXXXXXXKXXK    //
//    XKKXXXKKKKKK0Okdoodddddoolcc::;;,,'''..............                                        .....',,;;;;;:::::cccccccccclooodxO0XXXXXXKKXXXKXXXXXXXKKKK    //
//    KKKKKKKKKK0Oxdooddxxdoolcc:;;,,,''...........                                               .................''',;;:::::cloooodk0XXXXXK0KKKKXXKKKXXXKK    //
//    KKKKKKKK0Oxdoodxxxdoolcc::;,,,''''.......                      ..';::ccc::;,'.             ..... ....       .....'',,;;:::cllooodkOOkxk00KKKXXXKKXXXKK    //
//    KK000K0Oxdoodxxxxdollc::;;,,''''.'....                      .,cdxkkOOO0KKKKKKOxl,.         ..  ..   ..         ...'',,;;::cccclodooooloxO0KKKXXXKXXKXX    //
//    KKK000kdoodxkxxddollcc:;::;,,'',''..                 ..,,,,:dkkxdollodxO0KKKXXXXKkc.......  .. .     ..          ...',;;;:::cccloooodooodOKKKKXXKKKKXX    //
//    K000Odoodxkkxxddoollcccc::;,,,;:,..                'ldxkkkkkkkkxdoc::loxO0KXXXNNNNX0kkxoc;'.'''.       .          ....',,;;;::cccllooodddk0KXKKKKKKKKK    //
//    00Oxooodkkkxxddooooc:clc;,''''','...             .;xOkxxxxkkddxxolllccodk0KKXXNNNNNXX0kdl;'';ldo;.     .            ....',;;::::::cloddodxOKKXK00K00KK    //
//    0kdoodxkkxxxddooollc:;::,'''...''....       .,:looxkkkxxxxxxolddolloc:ldkOKKXXNNNNNXKOdl:,'';oxkkc.    ......         ...',;:::::ccclododdxOKKKKK0OkO0    //
//    xooodkkkxxddooolcccl:,,;;''....'....   ...'cx0000Okkkkxddxddoooooolc::coxO0KKXNNNNXK0ko:,,;coxO00kc..  .,.. ....        ...',;:cclloodddddddkKKKK0OkOK    //
//    oooxkkkxdddoollcc::c:;,;;,...'...    .:dkOOO00OOOkkkkkxddddoolccclc:;,;:oxO0KXNNNXXKOxl;,;cdO0KKK0xlc;;:,...   .        ......,;clodddxxxxdddk0XXXXXXX    //
//    ddxkkkxdddollcc:::;;:::;;;,'....   .;xO0000Okkkkkkkkxxxxxdoloxdlodl:,'';ok00KXNNXKKOko:,;cdk0KXXK0Oxolll.  .  .      ....'','..';:lodxxkkOkxddx0XXXXXN    //
//    dkOkkxddoollcc::;;;,,''''.......   .d0000OkkxxkkkkkOOkxddddoloodddl:,,,cdk0KKXXK000koc;;cokOKXXXK0Okxoll'          ....',,;;;,'.';:loxxkOOOkxddxOXXKXX    //
//    kOkkxdddolccc::;;,,,''......... ...,xK00OkkkdkOOxollldxxolododk0Oxol::coxO00KKX0xxkdl::ldk0KKXXXXK0Okxol:.        ....',;::cc::;;;::lodxkkO0OxddxOXXXX    //
//    OOkxxddolcc:::;;,,'''......''..,,;:lx00OOOkkkxdoc,'...;clxOxoodOOxooooodxkOO000Oo:lolldxO0KKXXXXXKK0Okxo:;,..       ..',;:cccllcccccclodxkO00Oxddx0XXX    //
//    Okkxddolcc::;;,,,''........,;;cdxkO0000OOOxddocc:,:c'.',;:odolodkxoc:::::ldxxkOOd,.,coxO0KKXXXXXXKK00Oxocc'.,. .     ..',;;::ccllllcccccoxkO00Oxddx0XX    //
//    kkxddolcc::;;,,,''.......';loxO0000000OO0Oxxdlcll:;;,;,':cokdlodkOkdoc:::codxkOOxc,..,coxO0KXXXXXXKK0Oxdlc::,.  .      .....'';:cclclooodxOO000OxddkKX    //
//    kxddolcc::;;,,,''.'''...,;lk000OkkkOOOOO00kOkxdxxdoclddollO0dloOXKOkdoolloddxkkdoc:;,.''';lkOOO0KK000Okdllxd.   ..           ..,;cloodxkkO000000kxddkK    //
//    xddolccc:;;,,,''..'','.,:oO00OkkkkkkkOOO00OOK0kdxkkkkxolxKXkolx0Oxxkkkxxxxxddl:;,'.........;oxk0KXXKKOOOxdl:'   ..           ..';:clodxxkOO00000Oxddxk    //
//    xdolccc:;;,;,,''.....';lok00OkkkkkkkkOOOO0OOOKK0Okkxxxk0KOdolx0kl:;;::cl:;,'....     ......,cxOKKXXK00Okxoc:,.               ....',;:cldxkkOO0000kdddd    //
//    doolcc:;;;,,,''......cxdx0OkkkkkkkkkkOOOkkkkkkOOO00000kxddodOKOo;,,''',,.......         ....,:dk00K000OOkxoc.                     ..';coddxkOO000Oxddd    //
//    oolcc::;;,,'''.......lolx0OkkkkkkOOOkkOOkxdoddxkxxkxxddxkO00Odc;,'''''.......'.           ...';lx0XXKK0Oxddl,                     ..',:lodxkkOO000kddd    //
//    ollc::;;,,,''.......'dl:kOkkkkkkkOOOOkOOkddddddxkkkkOO0KK0kdc;,'''.....';:::;'.           ....';cx0KK0Okkxol:.                 ....',;::clodxkkOO0Oxdd    //
//    olcc::;;,,''........'dl;x0kkkkkkxkOOOOOOOkxddddxkkkxxxxkxl:;,'..'..';lool;...              ....',:x0K0OOkxdo:.     ..  ..  ....'''',;;:::clodxkkOOOxdd    //
//    llc::;;,,'''.........lo;lOOOkkkxxxxkkkOOOOkkkxOOkddddolooc,''...';oxxo,.          ......'''''',,'.;kKK0kkxdo;      .'..,.  ...'''''''',;:lodxxkkOOOxdd    //
//    lcc:;;;,,''..........,o;,oO0OkxxkkkxkkOOOOOOO0K0Oxddddxkxo;',,,lk0Ol'         .,codkkOOOOOkxxddoc'.l0K0Okxdc.      ''.',.   ...''......';:lodxkkOOOkdd    //
//    lc::;;,,,''......... .,:,:ok0OkOOOkkkOOOOOO000Oxxxxddllolll;;d0XXOl'..       .'cxO0KKKKK0Okkxxxdo;.;OKK0kxo,        . ..     ......  ...,:clodxkkOOkdd    //
//    cc::;;,,'''.........   .',;ldk000OkkkO00000KOkxxddddl::c:;ckXWWX0Odc,..      .:xOKXXXK0OOOO000Okd:.'xKK0kxl.          .             ...';:codxkkkOOkdd    //
//    cc:;;;,,'''.........     .,;:dxkKKKKKKK000OOxxkdlooxo:;:oONWWNXKXX0kl,.     .;d0KXXK0OxoodxO0000Oo,.c0K0Oxl:'                        ..',;cloxxkkkOkdd    //
//    cc:;;;,,'''.........       .'',codkO00OOOkxxkkOxooddl:o0NMWKKKOxx00ko;.    ..:x0000kkkollcccooooxdc.,xK0kxkk:                          ..';clodxxkkkdd    //
//    cc:;;,,,'''.........          ...,;;lkkOOdl;:xxxkxodkKWWNKkooooooddoc,..   ..:dxxddlcc:;;,,,;::cloo:.cOOxxkd.                          ..,;cloddxkkxdd    //
//    c::;;;,,''''.........             .:lxkkOkdloxxdxO0XWNX0Oxocllloodo:,...  ...;coooc,,,;;;,,;:clllloo,,dK0kdc.                        ...,;:coodxxkkxdd    //
//    cc::;;,,,'''.........             ,k0kO0OOkkkOO0XNNKOxddoollclooodo;..... ..';:cll:,,,,;::cloooollodc'lKK0d;.                      ...',;:cloddxxkkxoo    //
//    cc::;;;,,''''.........            .lkxOKXXXXKKKXX0Oxdooollooooooxx:...... ..';::clc;;;;:cllodddooodxl,l00kl'                      ...',;:clooddxxkxdoo    //
//    cc:::;;,,,'''.........             ':lOXKKXXX0OOkxxdddxdllodddkkd:.........',::::clcccclllodddddxxkx::kOdl,                        ..';;:clloddxxxxddo    //
//    cc:::;;;,,,'''.........            ..;d0000XNXK0OOkxxxxxdxxkOOkl'.....'.....':c:;,;cooooooddxxxkOOkl:oOxl,                        ...',;:cloodxxxxxddo    //
//    dlc::;;;;,,''''.........            .':coxOKXNWWNXXKKK000K0Odl;..  ..',,...';lc:,...;ldxxkkkOOO0Okd:ckxl'                     .....',,;;::cloddxxxdddo    //
//    kdl:::;;;;,,,'''.........            .,;:ldOKXXXNNNNK0KKOdl,..;,.  .,cdxdddxkOkdc....';codxxkOOOkxl:kXKkc.                  ....'',;::::ccllooddxdoool    //
//    kdl::::;;;;,,,''''........            .';;cxOKKKKKKKOOOOx:...,;.   .ckKXK00KXNXKx,....',:cllodxxxo:oKNXXKo.                ....',;;;::ccllloooddddoooo    //
//    kkdl:::;;;;;,,,,'''........            .,:cdO0O00000OO00Okoc:c,.    .:cclk0KKKK0d.....',;:loodxxdl:xXXKKKd.              .....'',;;;::cccllooooodooooo    //
//    kkkdlllclc;,,,,,'''...........         .,,,:OXkxkOOOOO000OOxo;.         .,::ldo:'.....',;:codxxxo:cOXK0kl...               .....',;;:::::ccllooooooooo    //
//    kkkkxxxxxdoc;,,'''''............     . .';':ON0ddxkO00Okdoo:..          .....''.......',;clodxxdl:o0kc'.....                ......',;;;::cclloooooolll    //
//    kkkkkkkkkxxdc,,''''................  ....,;o0NXxlodxkOOxlc:'.        .'::;;;col:,'''',,;:coddddoc:kKx'  .''.               .....'',,;:::cccllloooooooo    //
//    kkkkkkkkkkxdc,,'''.......................':lkNW0ocloddoool:.....,,,;lx0KKKKXXXXKOdoooc:cllodddol:lKXO:   ,,             ......',,;::::cccllcccloolllll    //
//    kkkkkkkkkkkdc;,,'''......................;lo0NWNkccclollol;...':lcloddolloddddxkOOOxdolloodddol::OWNKx' .;;.          ....'',,;;::::ccclllllllllcc::cc    //
//    kkkkkkkkkkkxdlc:,'''.....................:ld0NNWNkc:clloo:,'........,;:::cllloxxxdlc:cloddddol:;xNWNX0c .,,.         ....',,;;;;::::ccllllllllllcccccc    //
//    kkkkkkkkkxddddol;''......................:ddkKNWWW0l:clolc;,,'.....',:oxkO0000OOkxdooodddddol:cONWNXKk;    ..      ....',,;;:::::ccccllllllllllllllooo    //
//    kkkkkkkkkxlc:::;,,'''..................,:cloodOXWWMNkl:lllc:;,''...'',,;;;;;:cclodddddxxddl:cxXWWNXKOd'     .    .....',,;;:::::cccccllllllllloooooooo    //
//    kkkkkkkkxxl:;;,,,,''''''..............,oc::cccoONWMMMXkolclc:;,'......       ..';:loddddlclxXWMWWNXKx;. .. .........'',,;;;;:::::::ccclllllllooooooooo    //
//    kkkkkkkxxxo:::cc:;,'',;::,............;olcc:cloONMMMMMWN0kdlcc:,'...          ..,:lodolldOXWMMMWWNX0l.   .. ......'',,;;::::::ccccccccccllllooooooooll    //
//    kkkkkkkkxxoccllolc;'.':cc;.............coodddxOXWMMMMMWNNWNKOxol:;,...........';codoodOXWNWWMMMWWNKl'.    ......'',,,;:::cccccccccccccccllooooooooolll    //
//    kkkkkkkkkxxolc;;;,'..',;:;'............':c,,dKNWWWWMMMWXXXNNWWNKOdlc::;;:clllcloddxkKWWWNNWMMMWWWNXd,.    .,.....',,;;::::cccccccccccllllooooooooooodd    //
//    kkkkkkkkkkkxxo;'''......................';''oXWWWMWWWMWXKKKKNNWWWNX0OxxdxxkkxxkO0KNWWWWNNNWMMMWWWNXKx,.  .'.....'',,;;;;;::::ccccccclllloooooooooodddd    //
//    kkkkkkkkkkkkxdl:,,''.....................,ok0KKXNWMWWMWKO000KXXNWWWWWWNXXXXXXNWWMMWWWWWNNNWMMWWNNXXKKkc......'',,,;;;;;;:::::cccccccllcclllooooloddddd    //
//    kkkkkkkkkkkkxxdoc;,,,'''................ckKOOkO0XNWMMMN0OOOOOO0KXXNNWWWWWWWMMMMMMWWWWNNNNNWMMWWNK00KKKOl'..'',,,,;;;:::::::cccccllloollcllooodoooooddo    //
//    kkkkkkkkkkkkxxxdolc::;;,,''............;kKK0OOO0KNWMMWXOOkkxxkkkO00XXNNWNNWWWWMWWWWWWNNNXNWMMMWNXKKKXXXO:'',,,,;;;;;::::::ccccllooooooolooooodoooooodo    //
//    kkkkkkkkkkkkxxxxxdoolc::::::;,'''',;;,';xKKKKKKKNWWWMN0OOkxxdddxxkkkO0KXXXNWWWWWWWWWWNNNXXNMMMMWWNNNNXXOc.,;;;:;;::::cccccccclooolllloooooooodddollddd    //
//    kkkkkkkkkkxkkxxxxxddoolcclllc;:c::clc:;;lOXNNNNWWMMMN0kkxxxddooooddoox000KNNWWWWWWWWWNNXXXXWMMMMWWWNNXKd,.;:;:ccccccccccclllllollooollooooodddddooodkO    //
//    xkkkkkkkkkxkkxkkxxxxdddoollccccllcclolc:o0XNWWWWWMMWKkkxxdddddocldolloddxOXNNWWWWWWWNNNXXXXNWMMMWWWNNX0xoc:;;clllllccllllloolloooooollooooddddoooxkO00    //
//    xxxxkkkkkkkkkkkxxxxxxxxdddoooooddollodxdxOKNNNWWWWN0kkxxddddddoc:llccclookKXXNWWWNWWNNNXXXXXNWMWWWWNNXXKK0kollooolllolloooooooooooooooooooddooddx0000O    //
//    OkkxxxxxxkkkkkkkxxxxxxxxxxxxxxxxxxdddxkOOKXNNNWWWXOkxxxdddoooool:::::cllld0XXNWNNNNNNNNNXXXXXNWMWWWNNNNNNXK0OxddoodddooodddoodooooooooooooooddxkKXXXXK    //
//    OOOkkxxxxxxkkkkkkkkxxkkkkkxxxkkxxxxxxkO0XNNNNWWN0kxxxxddooooolll:;:cclclcoOKKXNNNXNNNNNNXXXXXXXWWWWWWWNNNXXKKOkkxdddddddddddddddooodddolooxOkkk0XXKKKK    //
//    OOOOOkxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkO0XNNNWWNKOkxxddddoooollllc;;:ccllccoOK0KXXXXXNXXXXXXXXXXXXNWWMWWNNXXXXXK0OOkxdddodxkOkxdoodxkOOOOO00KKOk0KKKKKKK    //
//    OOOOOOkxxkkkkkkkkkkkkkkkkkkkkkkkkkkkOKXNNWWXKOOkxxddddolllllllccc::clcllcoOK0KKKKKKXXXXXXXXXXXXXXXNWWWNNNNNNNXX000OkxkkO0000OxdkO000000000K0OOKKKKKKKK    //
//    OOOOOOkkxxkkkkkkkkkkkkkkkkkkkkkkkkOO0XNWNX0Okkxdddddddllllccllccclc:ccclloOK0000000KXXXXXXXXXXXXXXXXXNNNNNWWNXXK00000O00000Okk000000OOkkkOOkO0KKKK00KK    //
//    OOOkOOOkxxkkkkkkkkkkkkkkkkkkkOOOOOO0KXK0Okxxxddddooooollllcc::ccclc;:clllokK00000O0XXKKK0KKKXXXXKKKKXKXXNNWWNNXXXKKKK00000OkOKKKK0OkkOOO0000O0KK000KKK    //
//    kkOOOOOkxkOOOOkkkkOOOOkkkkkkOOOOOOOOkkkxxdxddddddllooololllccccllc:,:cllcok000K00K0KK0OOOOOO0KXXXXXXXKXXXXXXNXNNNNNXXKKKK0O0KKKKOkk0KKKKKKK000KKKK000K    //
//    OOOOOOkkkkOOOOOkkkkOOOOOkkkOOOOkkxxdddddddddoollloolllllloollllc::ccccllcoO000K00OOOOOkOOxdxk0KKXXXXXXXXXXKKKKXXXXNNXXXXK00KKK0OO00KKKKKK00K00KKKKKK00    //
//    kOOOOOkkkkOOOOOOkOkkOOOOOkkkxddddolclllllloollc:;;::cllcccccccc::cccccloloO000K0OO000OOkdoxOO0KKKKKKXXXXXKKKKKKKKKKXXXXXXKKKK0O000OKKKKKKK0KK00KKKKK0O    //
//    kkOOOkkOkkOOOOOkkOOkkOOOOkxollol:;;clclooooolc:;;:;,';:ccc:;cllcc:;:ccloloO000K0OO0KK000xdO000KKKXKKKKXXXKKKKKKK0KXXKKKXXXXXKKK0KKO0KKKKKK0KKK00KKK0O0    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NouNou is ERC721Creator {
    constructor() ERC721Creator("Nouveau Nouveau", "NouNou") {}
}