// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Guardians
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                   ....................   ........                                              //
//                                ...............................................................                                 //
//                        ...................................................................................                     //
//                 ................................................................................................               //
//              ..............................................................................................................    //
//        ....................................................................................................................    //
//      ......................................................................................................................    //
//    .......................................................''''....''''''.''................................................    //
//    .....................................................'':lodooolc:;,,''''''''''..........................................    //
//    .........................................''''''''''';lkKXXXXXXK0koc:;,,,,,,'''''''......................................    //
//    .....................................'''''''''',,,,:xXWNKOkxxkKNNKxlc:;;;,,,,,,''''''''.................................    //
//    ...............................''''''''',,,,,,,,;;:dXWN0l'....;xXWKdlc:;;;;;,,,,,,,'''''''''....................''......    //
//    ....'',cl;'..'.'''.'''''''''''''',,,,,,,,,,;;;;;::lONWXo.    ..'kWXkolc:::;;;;;;;;,,,,'''''''''..''..........,;::;,,'...    //
//    ...,ol:okkoc;''''''''''''''''',,,,,,;;;;;:::::::cld0NWXo........dNXOxdolcc::::::;;;;,,,,,,,,'''''''''''''';cdkxlcldx:'..    //
//    ...'ckOkOOOOOxo:;,,,,,,,,,,,,,,;;;;:::cccccclllodxO0XNN0c......;ONXK0Okddollllc::::;;;;;,,,,,,,,,,,,,;;;cdOKKKOOO0Oo,'''    //
//    ..';cok0000OO000kol:;;;;;;;;::::cccclloooddddxkO0KKXNNN0;.....'o0XXXXXKOkxxdxdolccc::::;;;;;;;;;;;;;:cdOKXKKKKKK00Ol''''    //
//    ''',cxkO0000KK0OOOkxdolc::cldddddxxdxxkkOOO00KKXXNNWWX0d;.... .,oO0XXNNXK00OOOkxddoollllllllccc::clox0XXXXKKK0OO0KOc,'''    //
//    '',,,cx00000KK0000OOkkkkxddxkOO00K000KKKXXXXXXNNWWWNKkoc;'.....';ldOXXXXXXXXXXKKKK0OkkxxxxddddodxkOO0KKKXK0OOO0K0xc,,,,'    //
//    ,,,,;;:loddk00OOOOkOOkO000KKXXXXXXXXKKKXKKKKXNNWWNXOdolloc,'',;;;;:cx0XX00KKKK0KXXKKOkkkkOOOO00000000K0OOOkO00Oxol:;,,,,    //
//    ,,,;;;lkOkdodkOOOOOOOO0KXKXXNNNNNXXKKK00KKKXXXXXXKOolc:lxdolcccc::::cd0X0OO00000KKXXKK000KK0OOO0000OkkkO000OkkO00kc;,,,,    //
//    ,,,,;;:ok0XXKKKKXXXKKKKKXXXXXNXK0O0000KKKXXXK0KKK0xlc,.',;cc::;,,;:::coOK0O0K00000KXXXK0OOOOOO0KKK0OkkOOO0O0KK0doc;;,,,,    //
//    ,,,,;;;:cokKKKKKKKKKKKKKKXXXXXK0kxxxxk00O0KKKKKK0kdl:.....',,'',,.'ccc:oO00000000OOOOkOO00KKKKXXXXXX00000KKK0dl:;;;;,,,,    //
//    ;;;;;;:::coxOKKK0000O000KKXXXXOxoodollodk00KXXXX0koo;... .''.'','..lxollx0KKK0OkxddxxOO000KKXXXXXXXXXXXKKXXX0o:::;;;;,,,    //
//    ;;;;;:::::cclxkOOKKKKKXKKXXKXX0xlcccloddxkO0KKKKKOdo:... .......'..o0OxxOXNX0xolloddxkkOO00KXXXXKXXNNXKOOKOxdc::::;;;,,,    //
//    ;;;:::::ccccccclx0KKKKK0KXKKXXXKkdlcclooooodkO000Oxdl...  ....... 'kXK0OKK0xl::;;;:okKK00O0KXXXXXNNNXNXK0koccccc::;;;;,,    //
//    ;:::::::ccccccccoxkO0K000KXXXXXKK0Odl:;;::cllox0KK0Ol''.  ......  ;0XK0OOkdl:;:;;;:lx0KKKKKKXXKKK0Okkkkxolcccccc:::;;;;;    //
//    ::::::ccccccccllllldO0OOO0KKKKXK000Okdoc:::coooxOXNO;...  ....... .dX0kkkdll::::::lk000000KXXXXXX0OOkxdolllllcccc:::::;;    //
//    :ccccccccllllllllllooooodO000KKK00K0OO0OdlclodoxOKKl...    ........c0Okkxollllloxxk0KKK000KXXXNX0xddoooolllllllccccc::::    //
//    cccclllllllloooooooooooodxOO0KKKKKXK0OOKKkdodddkOKx' ..    ........,x0kxdolldxkOK00KKKK00KKK0kOOkdoooooollllllllccccc:::    //
//    lllllllllooooooooooooooooodxkO0KKKKKK000KX0kxxkO0k:.  .    .  ... ..:0OxxxddxkkOKKKXXXXKKKXXKOdooooooooooolllllllcccccc:    //
//    llllllooooooooooooooddooddddxxkOKKKKXXK000KKOkxkOo'....    ........ 'OKOOkkkO0O0K000KXXKK0Okxddooooooooooooooolllllllccc    //
//    llllllllooooooooooooddooddddxxkOOO0KXXXK0K0OOOOkkl....     ....'... .dXXK0OO0KKKXKOOOkOOOkdooooooooooooooooooollllllllcc    //
//    lllllllllllloooooooooooooodddddddk0KKXKKKK0O00OOk:....    .......   .cKWXXXKXXXKKKKOxddooooooooooooooooooooooollllllllll    //
//    cccclllllooooooooooooooooooodddddxxxxkO0KKK0KK0Kk:.....   ......   .':kNNNXXXXX0xxkxdoooooooooooooooooooooooooooolllllll    //
//    cccclllllloooooooooooooooodddddddxxxxxxxkO0KKKKXx;.....   .... .   .':dKNXXXX0kxdddodddddooooooooooooooooooooooollllllll    //
//    lllllllooooooooooooooooodxxxxxxkkxxxxxxxxxxkk0X0o,.....   ...  .   ';:lOKkkkxxdddddddddddddoooooddddoooooooooolllllllllc    //
//    lllllloollloooooooooooooodddddxxxxxxxxxxxxkk0XKkl,.....    ..     .';:cdOxxddddddddddddddddddddooddoddddddoooolllllllllc    //
//    lllllloollooooooooooooooodddddddxxxxxxkxkkk0XKOxc,'.....    .     .',:clkkxxxxddxdddddddddxddddddddddddddoodxddooollllcl    //
//    llollooooooooooooooooooooooooooooodddddxxkOKKdodc,'.....    .    ..',:::dOOkkkkkkkkkkxxkkkkkxxkxkkkxxxxxxddxkOkdooolllcl    //
//    cllcclllllolllooollllllllloooloooodddddxkOKKxcldc,'.....    .   ...',c:;cx0kkkkkkxxxxxxxxxxkxxxxkxxdddddddoxkOkolllccc:c    //
//    ,;;;;;;;;::::::cc::cccccccc::ccccclllllldxkoc;coc;'.....    .   ....,c:;:oOOddddxdddxxdddddxxddoddooooooooodkkdcc::::;;;    //
//    ..............''''''''''''''''''''''',,,,;,,,,;c:,......    .    ...,:;;::dxc::cccccccccccllccc:cccccccccccccc:::;;;;,,,    //
//    ........................'''''''''''''''''''''',::,......         ...,:;,;:lxl,,,,,,,,,,,,;;;;;;;;;;;;;;;;,,,,,,,,,''''''    //
//    ................................''''''''''''''';:'.......        ...,;,,;;:oo;',,''''',,,,;;,,,,,,,,,,,,,'''''''........    //
//    ..................................''''''''''''',;........        ...,;,',;:coc,,,,,,,,,,,,,,,,,,,,''''''''..............    //
//    ..............................''''''''''''''''',,........         ..,,,',;;;ll;,,,,,,,,,,,,,'''''''.....................    //
//    ...........................''',,;;;;;;;;;;;;;;;:;'.......         ..,,'',;;;co:,;,,,,,,,,,,''''''.......................    //
//              ..................'',cdxxxxxxxkkkkkkkkl'.......         .',,''',;;:lc;;;;;;;,,,''''''.........................    //
//               ...................';lolloooooooooooo:'.......        ..','''''',,:ccccccc:,'''''.........................       //
//                ....................'''''',,,,,,,,,,,'........       ...'''''''',;llccccc:,'........................            //
//                    ............................'''''.........      ....'''..''',::::::::;'....................                 //
//                               ...............................   ..............',;;,,;,,,,.............                         //
//                                 .............................       ..........''''''''''.............                          //
//                                  ............................       ..............................                             //
//                                      ..........................    .......................                                     //
//                                              ....  ............    ....''.................                                     //
//                                                       ..'............';;..     ........                                        //
//                                                      ..','...........,ll........                                               //
//                                                       ..'............'cl.......                                                //
//                                                       ...............'ll......                                                 //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GUARDIANS is ERC721Creator {
    constructor() ERC721Creator("Guardians", "GUARDIANS") {}
}