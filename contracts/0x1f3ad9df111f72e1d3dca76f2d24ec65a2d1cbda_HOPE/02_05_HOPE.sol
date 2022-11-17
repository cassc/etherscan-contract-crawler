// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Naomi Olson HOPE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    llllllllllccccccccc:::::::::::::::;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,'''''''''''''''''''''''''''''''''''''''...'''..    //
//    oooooollllllccccccccccc::::::::::::;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,''''''''''''''''''''''''''''''''''''''''''....    //
//    ddoooooooolllllllccccccccccc:::::::;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,'''''''''''''''''''''''''''''''''''''''''....    //
//    ddddoooooooollllllcccccccccccc::::::;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,''''''''''''''''''''''''''''''''''''''''.....    //
//    ddddddooooooolllllllcccccccccc::::::;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,''''''''''''''''''''''''''''''''''''''''''..    //
//    dddddddddooooollllllcccccccccc:::::::;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,'''''''''''''''''''''''''''''''''''''''''''''.    //
//    xdddddddddooooolllllcccccccccccc::::::;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,''''''''''''''''''''''''''''''''''''''''''''''    //
//    xxdddddddddoooolllllllccccccccccc:::::::;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,'''''''''''''''''''''''''''''''''''''''''''''    //
//    xxxdddddddddoooollllllllllcccccccc:::::::;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,''''''''''''''''''''''''''''''''''''''''''''    //
//    xxxxxddddddddooooooollllllcccccccccc::::::::;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,'''''''''''''''''''''''''''''''''''''''''''    //
//    kkxxxxxxxdddddooooooollllllllcccccccc::::::::;;;;;;;;;;;;;;,,,;,,,,,,,,,,,,,,,''''''''''''''''''''''''''''''''''''''''''    //
//    kkkkxxxxxxddddddoooooollllllllccccccccc:::::::::;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,''''''''''''''''''''''''''''''''''''''''''    //
//    kkkkkkxxxxxddddddoooooollllllllccccccccc:::::::::::;;;;;;;;;;;;;;,,,,,,,,,,,,,''''''''''''''''''''''''''''''''''''''''''    //
//    kkkkkkkxxxxxxdddddooooooollllllllllccccccc::::::::::;;;;;;;;;;;;,,,,,,,,,,,,,'''''''''''''''''''''''''''''''''''''''''''    //
//    kkkkkkxxxxxxxddddddooooooollllllllllccccccc::::::::;;;;;;;;;;;;,,,,,,,,,,,,,'''',,,'''''''''''''''''''''''''''''''''''''    //
//    kkkkkkxxxxxxxxdddddddooooolccllllllllccccccc:::::::::;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,'''''''''''''''''''''''''''''''''''''    //
//    kkkkkkkxxxxxxxdddddddoool:'..:olllllllcccccc:::::::::;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,'''''''''''''''''''''''''''''''''''''    //
//    OOkkkkkkkkxxxxddddddddddo:;,;ldolllllllcccccc:::::::;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,'''''''''''''''''''''''''''''''''''    //
//    kkkkkkkkkkxxxxxxdddddddxkxolcokdllllllllccccc:::::::;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,'''''''''''''''''''''''''''''''''''    //
//    kkkkkkkkkxxxxxxxxxxdddddddocc::loollllllccccc::::::;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,'''''''''''''''''''''''''''''''    //
//    OOkkkkkkkxxxxxxxxxxdllooooolc:,:oolllllccccc::::::;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,''''''''''''''''''''''''''''''    //
//    OOOkkkkkkkxxxxxxxollc::::cc:;;,;collllccccc::::::::;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,''''''''''''''''''''''''''''    //
//    OOOkkkkkkkkkkkkkkxxxxxxddxddol:;lolllccccccc:::::::::;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,'''''''''''''''''''''''''''    //
//    kkkkkkkkkkkkkkkkkxxxxxdooodxxxdlooddxdlcccccc:::::::::;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,,'''''''''''''''''''''''''    //
//    kkkkkkkkkkkkkxxdooooolllc:,;lxoododO0klcccccccc:::::::::;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,'''''''''''''''''''''''''    //
//    kkkkkkkxxxkxolc:ccccc:;;:oloxxdoooOKOdlccccccccc::::::::::;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,''''''''''''''''''''''''    //
//    kkkkkkkxxxl;;;;,,,;:clodxkxdooolloxxolllccccccc:::::::::::;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,''''''''''''''''''''    //
//    kkkkkkxkd:..',,:odxkOOOxdooooooollllllllcccccccc:::::::::::;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,,'','''''''''''''''    //
//    kkkkkkxo,..';ldkOkkxxdddoooooooolllllllllcccccccc::::::::::;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,;:::,,,,''''''''''''''    //
//    kkkkkxl'.',cdkkxxxxxdddddooooooollllllllllcccccccc::::::::::::;;;;;;;;;;;;;;;;;;;,,;;:::cloooolloodxdoc;;;;;,,''''''''''    //
//    kkkkkkoccloxxxxxxxdddddddoooooooolllllllllcccccccc::::::::::::::;;;:::;;:cc::coolldkOkkkkkxdddolloollllllccc::;,''''''''    //
//    OOOkkkkkkkxxxxxxxxxddddddooooooooolllllllccccccccc::::::::::::::lxkO0xoxOKOkkO0OO0KK0kkxddoooooloooooooolllccc:;;,''''''    //
//    OOOkkkkkkkkxxxxxxxxxxdddddddxdooolllllllllcccccccccc::::::::::cd0NXX00OOOOOO00OOO0OOkxdddddooooodddooooolllllc:::;,'''''    //
//    OOOOkkkkkkxxxxxxxxkkOOOO00OO00xodxdooolllllllcccccccc:::::::::oKNNXK0OOOOO0000OOOOOkkxddddddddddddoooollcccccc:::;,'''''    //
//    O0O0OOOOOOkkxxxxxxxkKNNXXXXXXK00KK0OkOOOkkkxdddxkkdlc:::::::::oKNNXXK000000Okxdxxxxxxxddxddoooooooolccc:::cccc::::;;,'''    //
//    0000KKKKKKK0OOOkxxxOXNNXKKXXXXXXXXXXXXXNXXXX0OOO00d,';cc::cdkk0NNNNNXKK000kxdooooooooddddddoooooollcccccc:cc::::::::::,'    //
//    000KXNNXXXXXXXX0OkkKNNXKKXXXXXXXXXKKXXXXXKKKK0OO00o'.',,',oKNNXXNXXXXKK0Okxddoooolllooooodddooooolllllccccc::::::cccc:,'    //
//    0000KNNNNXXXNNNXXKKXNNXXXXXXXXXKKKK0KK0KKKKKKK0000d'',''''oKXXKKKK0KKK00Okxddoooolooooolloooooooollllllcccccccc:ccccc;''    //
//    0KKKKXNNXXXXXNNNXXXNNNNNNXXXXXXKK0000000000KKKK00Kd'','''.:kO00KK000000Okxddoooooooooolllccclccllllllccc:::cccccllll:,''    //
//    00KXNNNXKKKKXXXXXXXXXXXXXNNNXXXKK00OOOO00000KKK00Kd'.''.'.;xOOO00000000OOkxxdddddooolllllcccccccccccccccc::ccccccccc,'''    //
//    OOO0KXNXXK00KKKKXXXKKKKKXXXNNXXXXK00O00000KKXKK000d,......;xOOkOOOkkkkOOOkxddddddooololllllllllccccccccccccc::::::::;;;,    //
//    OOOOO0KXXNXKKKKXXXKK000KKKKXXXXXXKK00000000KXK0000d,.''''.;dOkkkxxxxxxxkkxddddddddooooooollllllllllllcccccccccc::::::::;    //
//    OOOOOOOO0XNNXXXXXKK00OOOOOO000KKKK000K000O00KKKK00d'.,'',.,okkxxxxddddxxxxdddddddddddoooooooolllllllllllcccccccc::::::::    //
//    OOkkkO0KXNNXXXXXXXXKK0OOkkkkkOOO00000000OOkkk0KKKKd'.''''.,dkkxxxddddddddddddddddoooodoooolllllllccccccccccccccccccc::::    //
//    kxxkkk0KKXXXKKKKXNNXKKK0OOkkkkkkkkkkkkkkxxxxxOKKKKd'.''''.,oxxdddddddddooddddddddooooooooollllllllcccccccccccccccccc::::    //
//    OkxxdxxkkO000KKKKKK0OOOOkkkxxxxxxxxxxxdddddddOXXKKd'...''.,ldddddddddddooodddddddooooooooooollllllllccc::cccccccccc:::::    //
//    kkkkkkkkkkkOOOO0KK0kkxxxxxxxxxxxxxxxxxddddddd0XXKKo..''''.'ldoooooddddddddddddddddoooooooooolllllllllcccccccccccccc:::::    //
//    dddxxkkkkkkkkkkkkkxxxxddxxxxxxxxxxxxxxxxxxxdx0XXK0o..,'',.'lddooooooooooddooddddddddooolllllllllllllcccccccccccccc::::::    //
//    ooodddddxxxxxxxxxxxdddddxxxxxxxxxxxxxxxxxxxxk0XXK0o..,'',.'cdooooooooooooooooooddddddoollllllllllcccccc:::::cccccc::::::    //
//    ddddddddddddddxxxxddddxxxxxxxxxxxxxxxkkkkkkxkKXXX0l..'',,.'coooooooooolllloooooooooooooollllllllcccccccc::::::::::::::::    //
//    dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkxxxxxxxxxxxk0XKKKl....''.'coolooollllllllllllllllllloooolllcccccccc::::::::::::::::::::    //
//    xxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkxxxddddxxxxxdk0KKK0l..''''.':llllooolllllllllllllcccccclllllccccccc::::::::::::::::::::::    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxddxxxxxxxxOKKK0l..',,'.':ollllllooollllllllllcccccccccccccccccccc::::::::::::::::::::    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxk0KKKO:...''..':ooollllooooollllllllllllccccccccccccccccccccccc:::c:::::::::    //
//    0OOOOkkkkkkkkkkkkkkkkkkkkOOOOOOOkkxxxxxxxxxxkKKKK0c...''..':ooooooooooooolllllllllllllllccccccccllccccccccccccccc:::::::    //
//    0000OOOOOO00000OOOOOOOOOOOOOOOOOOkkxxxxxdxxxOK000Oc...''..':ooooooooooooolllllllllllllllllllllllllcccccccccccccccc::::::    //
//    0OOOO0OOOOO00000000000000OOOOOOOkkkkxxxxxxxxO00O0Oc.......'cdooooooollllllllllllllllllllllllllllccccccccccccccccccccc:::    //
//    XXKKKKKK0000OOOkOOOOOOO00OOOOOOOOkkkkxxxxxxxO0OO0Oc..''''.'cddooooolllllllllllllllllllllllllllllllcccccccccccccccccccccc    //
//    XXXXXXXXKKKK00OOOkkOOOOOOOO0OOOOOkkkkkkkkkkkO0OO0O:..',''.'cddddooooolllllllllllllllllllllllllllllcccccccccccccccccccccc    //
//    NXNXXXXXXKXXXXKKKKKKKKKKKKKKKKK00OOOOOkkkkkkO0OOOk:..',,'.'cdddddoooooooollloooooollllllllllllllllllllllcccccccccccccccc    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HOPE is ERC721Creator {
    constructor() ERC721Creator("Naomi Olson HOPE", "HOPE") {}
}