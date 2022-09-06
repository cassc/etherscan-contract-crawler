// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: uran
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    .                           ....';clodxxxxxxxxddolc:;'......     .....    ................    //
//    .....                   ...,cdk0KXNNWWWWWNNWWNWWNNNXK0Okdl:,.....................             //
//    .....              .....:dOXWWWNNNNNNNNNNNNXXXXXXXXNNNNNNNXKOxo:'..........                   //
//    .....................;o0NMMWWWNNNNNNNXXXXXKKKKKKKKKKXXXXXXXXNNNXOd;...                        //
//    ...................;dXWWWWWWNNNNXXXKKKK000OOkkkxxxkkkOO00KKKXXXXXNXkc.                        //
//    .................,lKWWWNNNNNXXXK0000000OkkxxxddoolcccllodxkOO0KK000KXOc.                      //
//    ...............':kNWWNNNNXXXKK0OO000OOxdoooolcc:;,'''',,;:lodkOO0OkOO0Kkc.                    //
//    ...............c0NWNNNXXXXKKK0OOO00kolc::ccc;,,,'.......'';:lodxkOOOOkkO0x;            ...    //
//    ..............c0NNNNXXXXKK000OOO0kdl::;;;ccc;;,''.........',:clodxkkOkkxkO0d,         ....    //
//    .............c0NNNXXXKKK000OOOO0koc:;::::c:;,''.............,:clodxkkOOOkOO00o'         ..    //
//    ......'''''';ONNXXXXKKK0000OO00koc::::;::;''........     ...';cllodxxkkOOO000K0l.       ..    //
//    .','''',;cloONNNNXXKKK0000000Oxolcc::;;::,''''''.'....   ....,:lllodxkkkOOOOO0KKOl;,,,''..    //
//    ,;cldxO0KXNWWNNNXXXKKKKKK00Okxddoolllcc:;,,;:::;,'..........',;:lllloxkxxkOOOOO0KKOdoodddo    //
//    k0XNWNNNNNNNNNXXKKKK00OOOkkkxxddollc::;,,,,,,,,,''''''',,,;::clooddddxkkxxxkkkkOO0KKkolood    //
//    WWWWNNNNNNNNXXKK000000000OOOkkkxdollc:;,''........',:clodxkkOO00000KKKK00000000OO00KXKOxdd    //
//    WWWWWWWWNNNNXXXXXXXXKKK0000KKKKK0Okoc,.         .,:oddooodxxkkOOO00KKKKXXXXXNNNNNXXXXXXX0x    //
//    NNNNNNNNNNNNNNNXXXXKKKXNNXNNXKOdllloxd;.       .:lc,..   ...,;cloddxxkkOOO0000KKXXXXXXNNNK    //
//    NNNXXXKKKKKKKKKKK0000KNWNNXKx:.     .:c;.   ...,,.          ..,;;;:ccllodxkkOO00000000KKXX    //
//    XXXXKK000OOOkxxxddoddxOXNX0x:...       .........          .....''',;:coddxkkkkkkkkkkkkkxxk    //
//    NXXK0OOOOOOkkxxdolcccclkXX0xc'.         .,'....          .'''''',,:cclodddddooollllllllllo    //
//    NXXKK00OOkxxddddddddddod0X0xl;..    .....,,....       .......',,;;:ccllcc::;;,,,,,,,;;;:cl    //
//    KKK000000OOOkkkkkxxxxxxxkKKkol:,'......';l:'...  .    .......,;;;;;;;,,'............',:cld    //
//    xddddxxxxxxxxkkOOO000OOkxkKKxdlc;,'...',co:,........     ..',,,''..........  .....,;clodkO    //
//    oollcccccclllloodxkOO0KK00KXKkdl;''..',;cc'..  .. ........'''........   .....'',;:cclooddx    //
//    doollccc:::;,,;;:clodxkOOOOKX0xollc;;,,:cc:,.   .. ............... .....''',,,;;::ccccccll    //
//    xddddoolcccc::::;;::::cclodxOK0kolc::::ccol:'..........   .............''''........''',,;:    //
//    oooddddoooooooooooooolcccclllxKKkdlcccclxkdc:::,'.....         .........          ...',;:c    //
//    cccccccllooooooddxxxddooooodddOK0kdooookOkl;;:::,'......                         ...',;:cc    //
//    ;,,,,,,,;:::ccclloddddoooooddxxkKK0kkkkOkol::;:;,'....                           ...',;;::    //
//    ,,''''.'''......'',,,;;::ccclllclkK0OOko:'.............                           ...,;:cl    //
//    :;;,,,,,,,'................'',,,';kKOkc.          .......               ...',;:cllodxkO0KX    //
//    lllc:;;;;,''............''',,,,;::d00Oc            .,'..       ...',;:clooddddddoollllllod    //
//    cccccccccllllllloolllooodddddxxxxxdk0Kkc..      ..';,.......',;:::::;,,''............''',;    //
//    xkOOO00000KK00OOkxollccc:::;;;;;,,,;oO00kxooooooolc:;:clooolcc:;,,''....         ......'',    //
//    KK0Okxdoolc:;;,,''............',:clldOKXKKKKKKKK0000000OOOOOOkkkkkkxxddddoollc::;;,'......    //
//    xdolc::;,,''.......   ...;cldk0KXNWNNNXXKK0OOkkkkxddddxddolcllcccllllccooddddddxxkkkkxxddo    //
//    kkxdool:;,,''.......;cdOKXNWWWNNNNNXXKKK00OOkxxxdoollccc:;;,,:c:::::;,,,;;;,',,,;:ccloodxx    //
//    kxxddollc::::;;;cokKNWNNNXXNNNXXXXNK0KKK000OOkkkxxddollc:;;;;;,,,'''.............''',,,,,;    //
//    OOkkkxxxddoodk0XNWNNXXXXXXKKKKKKKKK0kOOOOOOkkkkxxdddddolcc::;,'......  .           ..   ..    //
//    OOOkkxxdddk0XWWNXXXXXKKK0000000000000OOOOkkkxxxxxxxxxdddoollolc::;;,'....                     //
//    OkkkkkkOKXWWWNXKKKKKKK000000000000000OOOOOOkkkkxdodxdoooollllc::c:cc:;;,,......               //
//    OkkkkO0KKKKKKKKKK0000OO00O00000O00OOOkkkkkkkkkxxddddolccc:;;;,,,''.............               //
//    OOkkkkxxxxddddddxxxxxkkkkkkkkkkxxxxxxxxxxxdollcc:::;;,'''.......                       ...    //
//    kxddoc::::::cccloooddxxxxxxxxdddoooooollllc:;;,'...........                              .    //
//    dol:;,'.'''',;:clodddddxxxxxxddoooolllllc:;;,,'..                                       ..    //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract uran is ERC721Creator {
    constructor() ERC721Creator("uran", "uran") {}
}