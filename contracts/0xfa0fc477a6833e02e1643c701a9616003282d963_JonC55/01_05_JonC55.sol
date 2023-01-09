// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JonCaptures
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNX0OO00KKXXXNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOkkkxxxkkxlc:;;;;;:codxO000NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWXklccc:;;;::;,,''.'''''..';clldONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOkxoc;;:;,''',;::;;;,,,,;;,,'',,,,;lkKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKkddollc;,,'''''',;c::;;;;,,;;;,,;::;;,,:oOKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xoloooc:;,,,''',,',,;::;,,,,,,,;,,,;::;;,,,;lxKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xodddoddc;,,'',,;;;:;:;;;;;;,,;;,;;;,,,;;;;,,,,,:oOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkxdcccllllc;'',;cloddooodollcc::::::ccc::;;;;;,,,,,,:xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKddkxoccc:;;,,,:okO000OOkkkxxdddolllllllllllcc:;,,,,',:d0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxxOOxolc::;;;cdOKXXXKK0OOOOkkxxxxdddoddooooddoollc;'',:dKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOkO0Oxolc::;:oOXNNNXXK0OOOkkkxxxxxxxxxxxxxxxxxxxxxxdc,'cx0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0O00Oxocc::cd0NNNNXXK0OOkkkxxddddddddxxxxxxxxxkkkkkOOx:,,coxOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKKXXK0kdlcccokKNWWNXXK0OOkkxxdooooooooooddddddxxxxkkkOOOkc.';ldxOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXO0NNX0kdllodOXNWMWNXK0OkkkxddolllllloollooooodddddxxxkOOOkc..;oxxk0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXNNNKOxxxxkKNWWMWXKK0kkkxdoolcccccccllcllcllooooooodxkkOOk;.';odxOXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKXNXX0OxxxkOXWWWMWXK0OkxxddollcccccccccccccccllllllloodxkOOd'.':ookNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK0KNXK0Okxxk0XWWWWNKK0Okxdddoolcccc:::::::cccccccllllloodxkOk;..,co0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkxOKXKOkddx0NWWWNXXK0Okxxddddoollc:::::::cccc::cccllloodxkkk:..';dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0kk0KKkdlox0NWWWNXK00Okkkkxxxxdollcc::::::cc:::::ccllloxxxkk:...'lKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX00O0KKkolox0WWWNNXKKK0kkxkkxxxdollccc:::::::::::cclloodxxxkx;...':OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkxkk00kdlccdKWWNXXNXXKOkxdddoolllccc::::::::::::cclloddxxxxkd,...':OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOxdxxdlc:;ckNWWNKXNNX0kxoc:;;,,,;;:::::::::;;:::::clodxxkkkkl...';oKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0Oxolc::lkNWWNXXXNNKOxoc:;;;,,,,,;;;;:::c:;;;;;;;:clodxkkkx:..';l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOkxddodxKNWWWXOkOXKkdlc:;;,,,,,,'',,;:::c;,,,,,''''',;ldkOd,.,cxXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKxxxdxO0NMMMWNKkddxdl;,'...........',;:cc::;,,'.''''''';cdko''c0WMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0olodxKWMMMWNKOkdooddc;,'..........',:cccl:;'........'',;lxl':OWMMMMXdllll0MMMMNko:;,,;:oONMMMM0lllkNMMMWkllckNMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOc;:lkNMMMMWXKOkkkdlc::;;,,'''..'',,:lollo:,'............:dl;xNMMMMM0'    oMMWO,          ;OWMMo   .dWMMN:   ;XMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkc::oKWMMMMWX0O00kdlc:;;;,,,,,,,,,;:okxoool:,..........',;oclKMMMMMM0'    oMMO.    ;dd;    '0MMo    .kWMN:   ;XMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkxOdoONWMMMWXXXXKOxolcc::::::::cccloxOkdodolc;'.....'',;clolxNMMMMMM0'    oMWc    ;XMMK;    lWMo     'OMN:   ;XMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOOOxoxXWMMMWWWNX0kdolcc::::::::coxkkkkxoodxxoc:;,''''',;cloxKMMMMMMM0'    oMX;    cWMMN:    ;XMo      ,KN:   ;XMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkdddx0WMMMWWWNX0kdlcc:::;;,,,;cloOK0xolloxxkxoc::,,,,;:clo0WMMMMMMM0'    oMK,    cWMMN:    ;XMo       :0:   ;XMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOkkkxKWMMMWWWNK0kdlc:;;;,''':xkdoOKOdlcccloxkl;;:;;;;;:cldKMMMMMMMM0'    oMK,    cWMMN:    ;XMo        :,   ;XMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kddkOk0WMMMWNXNXK0kdl:;;,''',,:oxk0XKxl:::::cldd;',,,,,;;cokNMMMMMMMM0'    oMK,    cWMMN:    ;XMo   .c,       ;XMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWNKOxol:;cdx0WMMMWNKKKK0koc;,,,,;:::::;:oxkxl;,,,;;;ld:.'''',,;co0WMMMMMMMM0'    oMK;    cWMMN:    ;XMo   .xk.      ;XMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWXOkdoc;;;;,;o0WMMMWX00K0kdc;',:clllcccc:,'',:;,''',,;c:,...''',;cxXMMMMMMMMM0'    oMX;    cWMMN:    ;XMo   .xWd.     ;XMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWXK0xollc:;;;,;:lo0WMMMWX00Oxdl:,,:odolc:;,,,,,'.......',;::;'...'',:lOWMMMMMMMMM0'    oMN:    :NMMX:    cNMo   .xMNc     ;XMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNXK0Odlc::::;;,;okkkKWMMW0lc:;,,,''';lloooooc::c:'.....'''',;:c;'.'',:lo0MMMMMMMWNXo.    dMMx.   .o00l.   .kMMo   .xMMX;    ;XMMMMMMM    //
//    MMMMMMMMMMMMMMMWX0O000xlc::;;;;,dXKOOXWKkd:''.''......'';::cllcloc,'....',;::ccc:,',;clloKMMMMMMMO;.     ,0MMNd.    ..    .xWMMo   .xMMM0'   ;XMMMMMMM    //
//    MMMMMMMMMMMMMMWXKKKK0Okxxdl::c:dXWXKKXk;''''''''''''''...,,;:;,,,,''...',,,,;::::,';cllcdXMMMMMMMk'....,l0MMMMW0o;.....';oKMMMMk;,,:OMMMMk;,,oNMMMMMMM    //
//    MMMMMMMMMMMMMMWNXNWNK0OkxxddolxXWNXKOd:';odllolllocco;...';ldc:,'......''',,,,,,;,,:llcckWMMMMMMMNKKKKXWMMMMMMMMMWNXKKXNWMMMMMMMWWWWMMMMMMWWWWMMMMMMMM    //
//    MMMMMMMMWNXXXXXKKXX0xdollldkOk0WNXKOo,'',cc;;;;,,''.'.....,cooc;,'...',;;:loool;;::llc:oKMMMMMMMMWOc::l0WM0loKMKo::ckkl:::okooKXdl0Oc:clkNk:ccdOx::cxN    //
//    MMMWNXKOkxdxkkxxxkxdllccclllollcc:;cc'.''..................,;;,'.........':llol:;:ccc:ckWMMMMMMMMO..lc ,0Nc  dWO..:'.ox' ,Od..O0'.do 'o'.dc ,k0l 'o;;O    //
//    NNK0Okxxxdddxxxdddolllllol:''''....''.....................................';;cl;,;::::cdk0XWMMMMMx..OKooKO...;XO..;'.kN: cWk..O0'.xo 'c..xc .oKO'.:xXW    //
//    00Okkkxxxxdddddddolllcccll:,,;;'''''..',;:ccc::;;;,,'............,;;'..........',;;;;c;...;o0WMMMx..OXxkXo ;,.xO. ,oONN: cWk..O0'.xo .. oNc .l0WKo..cX    //
//    0OOkkkkxxxddooooolc;,,,,,''';c;'''',cdkkkkxxddooollcc::;,'.......'''..............',:l:....':kNWMk..xd.,x; ;' ck'.xMMMN: lWO..xk..ko ;l.;Kl ;KWk;lx'.x    //
//    OOkkkkxxdddollllllc::c;,,'''''''':ok000Okddddolllllllccccc:;,......'............  .;col;.....,:dKXd,;,,kk,cKO;cxc;OMMMNo.dWNx,;;,oXx'o0l,xd.,cdkl,;,cK    //
//    kkkxxxxxxxdl:;;;;;;:cc;''''''',lk000Oxol:;,,,,'.'',,;:ccllccc:,............... .. .;c:,.........;oxxkOXWNXXWNXXNXXNWWWWNXNWWWXKKXWWNXXWNXXNXXXXNNX0KNW    //
//    kxk0KOxxxxoc;;;;,,,;,,'''''',ck0Odl:,'.................',;cccc:;'..............   .''.   .......... ..',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;k    //
//    dkNX0klcllc:;;;;,,,,,''''',lxkdc;'................''.......;lllc:,..............  ...     .  ......    ....,:ldxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkX    //
//    o0Nkllc::;:;;;;;,,,,,'''':odl;,,,'..........................':llcc,. .  ........   ...       ...............';cdkKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    oxko:ldocc:::::;;;;;;;;;col:;,,'''''..........................,cll:'...  .  ....    ..      ..   ... ...........',:oxOKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    oxkxxO0OOOkkkkxxxxdxxxxolc;,,',''''.............................;ll:. ..    ...        ..       ...   ..............'',:ldkKNWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    KKK00OOO0OOOOOkkxxxxxxoc:,',,,,'..'..............................'lo,.     ..          ...        ..      ................',cokKNWMMMMMMMMMMMMMMMMMMMM    //
//    X0OOkkkkkkkkkxddooooolc;',;;,''....................................c:.                  ..                 ...................',cdOXWMMMMMMMMMMMMMMMMM    //
//    Okkkxxxxxxxxxddoooolcc;,;:,'...''...................................;.                  ...                 ......................':ok0NWMMMMMMMMMMMMM    //
//    Okxxxxxxxxxxxxdoollc:;,;;,.....''......................................                 ...                 .... ....................',cxNMMMMMMMMMMMM    //
//    kxxxddddxxxxxdoollcc;,;;'.....'..................................  ...                  ...                          ...................'l0WMMMMMMMMMM    //
//    kxxddddddoooollccloc,,,'.....................''.....    .....  .    .                    .                .      ..................    ...,lONMMMMMMMM    //
//    kxdooollccc::cc::ldc','.....'................'.......    .....                                                         .  .......         ..'l0WMMMMMM    //
//    xxxxxxddollcccclccc,','.............................     ......                                                     ..........              ..,oKMMMMM    //
//    0OOOK0kdolllccllll:,''.............................     .......                                                            ..                 ..;kNMMM    //
//    Okk0KOxddollcclldko,''........................... .     ......                                               ..      .....                      .'lKWM    //
//    kkO0Okxdoolllllldxo;''..........................       .......                                               .                                   ..;kN    //
//    kkOkkxxddollloodol:,''.......................         .......                                                      .                               .'l    //
//    OOkkxxdooolllccc;;,'''....''..............            ......                                                .... ...                                 .    //
//    kkxxdoc:;;,'''''..',,......'...............          ......                                                                                               //
//    dolc:;,,,,,,,,,,,,;;,'.......................  ..    ......                                                    ......                                     //
//    lllccccccccccccccccc:,'..........................   .....                                                                                                 //
//    ooooooooooollcccccccc:;,...................... .   ..                                                                                                     //
//    oooooooooooollcccccc:::;'.................                              .                                                                                 //
//    oooooddoooooolcc:::lolc;;,'.............                           ..  .                                                                                  //
//    loddddddoooolc::;:lxkxoc::;,............                .                                                                                                 //
//    oodddooolccc::;;:okOOkxl;,,,..............             ... ..    .                                           .  ..                                        //
//    ooddooolcc:;;:clxOKKK0kl;,''....... ......................                                                                                                //
//    doooooolcc:::ldOKNNNNX0o;,,',,'....  ..'.....................                                                                                             //
//    :::ccccc:::coOXWWMMMWN0o,'..','.....  ...............  .  ..                                                                                              //
//    ,,,,,,,,;;:oONWMMMMMWNOl,'...'......  ................                                                                                                    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JonC55 is ERC1155Creator {
    constructor() ERC1155Creator("JonCaptures", "JonC55") {}
}