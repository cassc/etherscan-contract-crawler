// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Postcards from the world
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    llll;.......................;lddxxxxddddoolc:,,'.'';;;:clodxkkkkkkkkxxxxxoc:;..    ..',:cloddxxxkkkkkkkkkkkkkkkkkkkxxxxdddxxxkkkxxddoodooooooooooooddd    //
//    llllc,......'''''....''''',,codxxxxxddddoolc;,,;:cloddxxkkOOO00000OOOOOkkxol:'.......';:lodxxkOO0000000000000OOOOOOOkkxdooodkOO0OOOkkkkkkkkkxxxxkkkkkk    //
//    ooooolccccccccccc:::::::cccclodxxxxxddddolc:;:codxkOOO00000KKKKKK00000OOkkdoc'...''',,;cloddxkOO00KKKKK0000000OOOOOOOOkxdoldxO0000OOOOOOOOOOOOOOOOOOOO    //
//    ddddoollllllllllllllllllllllloddddddddddoolclodxkOO000000KKKK00000000OOOkxoc;..',,;::ccloodddxxkOOO00000000OOOOOOOOOOOkkxdodxkO0000OOOO0OOOOOOOOOOOOOO    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxkxxxxxxxxxxxkkkkxxkkkOO0000000000000OOOOOOOkkxxdl:,..',;:cloooodddddddxxkkkOOOOOOOOOOO00000OOkkxdolcc::clxO0000000OOOOOOOOOO    //
//    kkOOOOOOOOOO00000000000000000000OOOOOO0000000000000000000000OOkkkkxxxxxddolcc::::cloodddddddddddddxxkkOOOOOOOOOO00000Oxdc;'..      'd00000000OOOOOOOOO    //
//    00000000KKKKKKKKKKKKKKKKKKKKKKKKK000000KK00000000000000000OOOkkxxxddddddddoooooooddddxxxxxxddxxxxxxxkkkkkkkkkkOOkxoc;'.            .:O0000000OOO000000    //
//    00000000000000K00O0000KKKKKKKK0000000000000000OOOOOOOOOOOOOOOkkkxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkOOOkkkxdl;..                  :O0000000000000000    //
//    0000000000000kolc::::::cloodxkOO000000000000O00000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO000000000ko:'.     .........       .lO0000000000000000    //
//    KKK00000KKKK0o,,;,,,,''',,'',;:codxk0KKKKKKKK0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00000KKKKKKKKKKKKKKKKKKOl'    .................    ,kKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKd,',,''............',,;ldk0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXXXXKKKKKKXXXXXXXXXXXXXXXXOl.    ..................    .oKXXXXXXXXXXXXXXXXX    //
//    KKKKKKKKKKKKXO:.,,,'................'';:ok0KKKKXXKKXXKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0o.    ..................    .'oKXXXXXXXXXXXXXXXXXX    //
//    KKXKKKKXXXXXXXk;.'''..................''';lx0KXXXXXXXXXXXKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKx,.   .   .........'''........;kXXXXXXXXXXXXXXXXXXXX    //
//    KKKKKKKXXXXXXXXk:'.... ................''',;cdOKXXXXXXXXXXKKKKKXXXXXXXXXXXXXXXXXXXXKKKKKKXXXXXXKkc.   ..   ....'''','''''...''.'dXXXXXXXXXXXXXXXXXXXXX    //
//    KKKKKKKKXXXXXXXXKk;     .................',,,;ldOKXXXXXXXXXXKKKKXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKOo'..  ..   ...',;;,,;;,,'...,;;,c0XXXXXXXXXXXXXXXXXXXXX    //
//    KXXXXKKXXXXXXXXXXXk'    ...................',;;;cok0KXXXXXXXXXXXXXKKXXXXKKKXKKKKKKKKKKKKKKK0ko;...  ... ..',;;;;;;:;,'...';:;,:kKXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXNNNXXXd.  ................'''.',,''',,cxOKKXXXXXXXXKK0Okxddoodxxxkkkkxxkkkkkxdl;....  ... ..,,;:dkxool:,,,,:ccc:ckXXXXXXXXXXXKKKKKKXXXXXX    //
//    XXXXXXXXXXXXNNNNNNNXl.  ......'''''.''',,''..........;oxxxkkxddolc:;,,'',::;:cc::c:::cooolc;'...    ....;;,';lxOOxc::cllooc:lkKXXXXXXXKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXNNNNNNKc.  ......''''''''''''..   ......''.........''',,,,::,,,;,,;cclloddddoc;'...   ...,::;,',,;;;;:cldddc:oOKKKKKKKKKKKK000000KKKK000    //
//    XXXKKXXXXXXXXXXXXXNXN0c.  ........''......'..       ...     .....',,,'.';:::::;,;:clodddxxddoc,..  ...,:;;;,'......'':oo;,o0KKKKKKKKKKK000000000000000    //
//    XXXXXXXXXXXXXXXXXXXXXXKl.  ..................               ......'.....,clllolcclloddxxxxxxxooc,.....;:;;,'..........'..lO0000000000000000000000KKK00    //
//    KXXXXXXXXXXXXXXXXXXXXXXXd.  .........   ....               ..........',,';:cclllloddddxkkOOOOkkxoc,''',','.........     'd00000K00000000000000000KKK00    //
//    KKXXXXXXXXXXXXXKKKXXXXXXXx,  ........... .....         ............',,,,'',;;:clooooolodxkO00Okxkxl;,'.......... .'..   ,k00000KK000000000000000000000    //
//    KKKKKKKXXXXXXXXKKKKXXXXXXXO;       ......  ....        ............',;;,'',;;:cloll:,'',;::coddoolc;,'.......... ...   .l000000K0000000000000000000000    //
//    XKKKKKKXXXXXXXXKKKXXXXXXXXXd.        .....                           ...............                 ...  ......     .,ck000000000000000000000000KKKK0    //
//    KKKKKXXXXXXXXXXXXXXXXXXXXXX0:         ....                                                      ..        ....      'lkOKKKKK000000000000000000000KK00    //
//    KKKKKKKKXXKKKKKKKKKKKKKKXXKKk'         ..                     .:;.                             'kK:      ..       .;dOKKKKK000000000000000000000000000    //
//    OOOOOOO0000000O00000000000000d,.                 ;xxo;.    .;xXMK,                'coc'.      ;0MWl      ,,.     'lkOOO00OOOOOOOOkkkkkOOOOOOOOOOO0000O    //
//    dddddddxxxxxxxdxxxxxxxxxxkkkxxdc;'.             ,KMMMWKd:,lONMXx,                 :0NMNOo;.  :KMMK,      'c:'  .;loddxxxxxxddddddoddddddddxxxxxxxkkkkx    //
//    lllllllllllllllllllllllllooooolllll:'.           ;xKWMMMWWWMXd'                    .,lkXWWKxkNMMMx.      .cc;',::;;::::cccc:::::::::::::::c:::::cccccc    //
//    clcccccclllllllccccccllllllllllllllllc;.   .       .oNMMMMMMKc.                        .cOWMMMMMMk,      .;:;;;;,,,,;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,,,    //
//    llcccccccclllllllccccccccccllcclllllllll:;,,.      :OWMNXWMMMW0o'          ..           .xWMWXNMMMNOc.   .;;,,,,,,,,;;;;;;;;;;,,;;;;;;;;;;,,,,,,,,,,,,    //
//    lccccccccccclllllllcccccllccccllllllllllllll,    'kNWKo'.;oOXWMMNk,      .cxxl.        .xWWk;.,cxKWWo.  .';;;;;;;;;;;;;;;;;,,,,,,;;;;;;;;;,,,,,,,,,,,,    //
//    lcccccccccccclllllcccclllllcccccllllllllllll;    cKOc.      .;coxk;     .oXXK0o.      .dWXl.     .,;.  .,::;;;;;;;;;;;;;;;;,;;;;;;;,,,,,;;;,,,,,,,,,,,    //
//    ccccccccccccccclllccccccccccccccllllllllllll;.    ..                   ,kNWWWWK;       .c,             .;c::::::;;;;;;;;;;,;;;;;;;;;;;;;;;;,,,,,,,,,,,    //
//    cccccccccccccccllllccccccccccccccccccccccccl:.                         lNNNNNWMO.                      .:c::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,'''    //
//    ccccccccccccccccllccccccccccccccccccccccccccc:.                    ..,:xXXXKNWMK; ..                  .,lc;:;;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,''    //
//    cccccccccccccccccccccccccccccccccccccccccccccc;..           .... .:dO0KK0OO0KXNNxoxdc:;'.      ......'cxdc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,    //
//    cccccccccccccccccccccc::cccccccccccccccccccccc:'....... ...,od:'..,;:cllccclloxOXNN0xxxdl,..''';c;,;;lxOxc:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,    //
//    ccc:::::ccccccccccccc:::cccccccccccccccccccccc:,....'......cxl,..  ...',:cccclodxOXX0Okkdoloolcc:,',:dkko:::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,    //
//    ccccc::cccccccccccccc:::ccccccccccccccccclllcc:;'.........,ll;'..   ....;cloodxxdx0000Oxxdooolcl:,,cdkkdl:cc::;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,    //
//    ccccccccccccccccccccccccccccccccccccccccccccc:,......'....:l:,'.     ....',;,,;ccoO0O0kxxkxolllol,;oxxddddooc::;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,    //
//    cc::cccccccccccccccccccccccccccccccccccccccc:,. .....,,..':ol,..     .  ...    .:dKOxxkxdxxddoooc;:oodxxdddlcc::;;;;;;;;;;;;;;;;;,,,,,,,,,,;,,,,,,,,,,    //
//    cccccccccccccc:::::ccccccccccccccccccccccccc:.   ....''..':od:.      .  .;cc;'.:d0Kkdooodxxxxdol::cldxxodxxolol::::::;;;;;;;;;;;,,,,,,,,,;;;;;;;;;,,,,    //
//    dddddddddddooooooooolllllllllllllllllcccllcl:'. .. ......;cooc;..    .  ..,;;,;x0K0kdoloddxxddl;';cddoddxxxxxdooc:::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,    //
//    OOOOOOOOOOkkkkkkkkkkkkkkkxxxxxxxxxxxxdddddddl'.... ....'',clc;:;'...... ...',:dkOOkxdollodxxdoc::oxdccdooodo:;;col:;;;;;;;;;;;;;;;;;;;;;;;;;;;,;;;;;;;    //
//    00000000000000000000000000000000000000OOOOO0x,.  .  .....':cc:,,,,,'.'..':clodxxxxdddolodoodddoool:,';:,,,,,..':ooc:;;;;;;;;;;;;;;;;;;;;;;;;;,,,,;;;;;    //
//    K00K000000000KKKKK00KKKKKKKKKKKKKKKKKKKKKKKKk,    ..   ..',:clc::;;;;:,.;llodxxxxxdoolllollooolc;'............,lolcc:::::::::::::::;;;;:::;;;;;;;;;;;;    //
//    KKKK000000KKKKKK000000KKKKKKKKKKKKKKKKKKKKKKx'    .     ..',:oolcc:;;;;',;::cllloolooooccloddc;,......       .;dxxxddddoooooddoooooolllllllllccccccccc    //
//    KKKK000000KKKKK000000KKKKKKKKKKKKKKKKKKKKKKKx:.   .       ..'ldxdoc;:::cloodddxxkkOK0xoccdk0kc'.....         .:dkOOOOOOkkkkOOOOOOOOkkkkkxxxkkxxxxxxxxx    //
//    0KK00000000KKKKKKKKKKKKKKKKKKKKKKKKKKKXKKKKK0kc.             .,cdxxoccloodxkO00KNN0dc:cox0XNO:..            ..;ok00KKK0000000KKKKKKKK0000OO0000OOOOOOO    //
//    00000000000KKKKKKKKKKKKKKKKKKKKKKKKKKXXKKKKKKKk:             ...,lxkxddddxOO0XXXKOocldk0XNWNOc..            ..;lk0KKKKKKKKKKKKKK000KKKKK000000000000OO    //
//    0000000KKKKKKKKKKKXXXKKKKK00000KKKKKKKKKKKKKKKO:               .'cdxxxxxkkkkkOkkkOO0KNWWWWWNOc.            ..',lk00KKKKKKKKKKK00OOO000K000000000000000    //
//    00000KKKKKKKKKXXXKXXXXKKK000000KKKKKKKKKKKKKKOl.               .,loooodxxxxxxxxkOKXWWWWWWNXKk:.            ..';okO000KKKKKKKK000OOO0000KK0000000000000    //
//    O0000KKKKKKKKKKKKKKKK000000000000000000000000kl,.              .,::clodxxxkkkkkO0KNWWWWWNKkxd:.          ....';okO000000KKKKKKKKK0000KKKKK000000000KKK    //
//    00000KKKKKKKKKKKKK00OOkkOO0000000000000000KK00x:.              ...';codxxkOOOOOO0KXNNNNNXKOxdc.         ....';lxO000000000000KKKKKK00KKKKKKKK0KK000KKK    //
//    K00000000KKKKKKKKK00OOkxkkOO00000000000KKKKKKKOo.              .. .,lddxO0KXXX0O0KXNX0OOkxoc:;.     .. .....,lxO0000K0K000000000KKKK0KKKKKKKKKKKKKK00K    //
//    K0000000000000000KKK00OOOOOO00000000000KKKKKKKKk;.              .';oddxO0KNNWWXK0OOKX0dllc;,...     .......';lxk0000000000OOOOO00KKK00000000KKKKKKKK0K    //
//    00000000OOO00000000000000OO00000000000KKKKKKKKK0o,.           ..';coolxOOKWWWWNXK0kkOOxoc:,,'...     ......',:ldk00000KKK00OOO0000KKKKKK000000KKKKKKKK    //
//    0000000OOOO0000000000000000000KKKKKKKKKKKKKKKKKKko'...         ...',:looxKXNNNNNX0kkkxxoc;;;::,.      ...,;,,;:cldO000KKK00000000000KKKKKKK000000KKKKK    //
//    0000000000000000000000000000000000000KKKKKKKK00kc....            ....,:clxkk0XXNX0kkkxl:,..';,.      ...;:;''',,;cdO00000000000000000000KKKK000000KKK0    //
//    00000000000000000000000000000OOO0000000000000Od;.                    ....',,cxO00OkOkddl:,.','..    ...;;;;;,'''',cx000000000000000000000000000O000000    //
//    000000000000000000000000000OOOOO000000000000Oo'.                      .......';lxkkkxlcc:'......     .;l:,;;;,,'',:lxOOOOOOOOO000KKK000000000000000000    //
//    0000000000000000OO000000OOOO0000000KKK00000Oo'                ...    ..... ....:dxkdc::;,...       .',':c;'...'',;:coxOOOOOOOO000KKKKKK000000000000000    //
//    0000000000000000OO0000000000000000KKKKKK000k:..                   .............,loll:'''...   ....'',,.':c,...  ..';lxO00000OO00000000K000000000000000    //
//    OOOO000K00000000000000000000000000KKKKKKK00Oc.                    ..............',',;'...... .;c::l:.....',,.    ...;ok00K00000000000000000KK000000000    //
//    OOOO000000000000000000000000000000000KKKK000o.                       ........................;xd::c;...  ....   ....,lk00000000000000OO000KKK000000000    //
//    OOOO0000000000000000KKK0K000000KKK000000000Kk;.                           .................',o0x:,'.             ..;lxO00000000000000000000K000000OO00    //
//    OO0000000KKKKKKKKKKKKKKK0K0000000000000000000x;.           ....          .    ..':lc;'..'''''lkdc.               .;xOO00000OO000000000OO00000000OOOOO0    //
//    000000000KKKKKKKK000000000000000000000OO000000d.          ...''..  .....''..   'o0XX0o,',','.cxo:.           .  ..lO0000000OO00000000OOO0000000OOOO000    //
//    000000000KKKK000000000000000000000000000000000d.        .....',.   .......     .l0XNNKx:,'..'cxxoc'... .  .......,lO0000000000000OOOOOO0000OOOOOOO0000    //
//    KKKKK00000000000000000000000000000000000000K00d.    .   .....'..      ......  ..,dKNNWNk:...:loddkKd;..........,:clx000000000000OOOOO00000OOOOOOOO0000    //
//    KKKKK0000O0000000000000000000000KKKK00000KKKK0l.        ........         ........,xKXNKkl'..ol,,'c00c,;,'...'';clooxO000000000000OOO000000OOOOOOOOOOOO    //
//    KKK00000000000000000000000000000KKK0000000KKKk,            ..';.         ...'''''cOKXXKOdc',xd'':x0x;;;,;,,,;;collclk00000000000OOOO000000OOOOOOOkkkkk    //
//    0000000000000000000000000000O00000000000000KKx.            ..',..         ..''.':d0NWWNKkxc:dkllOKk:.;;,;;;;:clolc:;oO0000000OOOOOOOO0000OOOOOOOOOkkkk    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ROOKMATE is ERC1155Creator {
    constructor() ERC1155Creator("Postcards from the world", "ROOKMATE") {}
}