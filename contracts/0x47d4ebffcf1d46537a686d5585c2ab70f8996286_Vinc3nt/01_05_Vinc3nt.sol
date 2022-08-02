// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vinc3nt
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                       ..              ......'''',,,;;;::::::::ccc::::::::::::::::;;;;,,,'''.....                               //
//                       ..               .....''',,,,;;;;::::::::cc::::::::::::::::;;;,,,,'''......                              //
//                                       ......''',,,,,;;;;::::::::::::::::::::::::;;;;,,,''''.......                             //
//                               ..............''',,,,,;;;::cllllllllcc::::::::::;;;:cloddddool:,'....                            //
//                           ...',,;;;;;;;;,,,,'''',,,;clodxkkkkkkkkkkxddoc::::;:oxOKXWMMMMMMMMWX0ko;.                            //
//                        .',,;;;;;;;;;;;;;;;;;;;,,,:oxkkkkkkkkkkkkkkkkkkkkxolokKWMMMMMMMMMMMMMMMMMMNOo,                          //
//                      ..,;;;;;;;;;;;;;;;;;;;;;;:ldkkkkkkkkkkkkkkkkkkkkkkkO0XWMMMMMMMMMMMMMMMMMMMMMMMMXx'                        //
//                     .,;;;;;;;;;;;;;;;;;;;;;;;cdkkkkkkkkkkkkkkkkkkkkkkkkOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.                      //
//                    ';;;;;;;;;;;;;;;;;;;;;;;;lxkkkkkkkkkkkkkkkkkkkkkkkk0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.                     //
//                   ';;;;;;;;;;;;;;;;;;;;;;;;lxkkkkkkkkkkkkkkkkkkkkkkkkONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.                    //
//                  .;;;;;;;;;;;;;;;;;;;;;;;;:xkkkkkkkkkkkkkkkkkkkkkkkkOXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc                    //
//    .             ';;;;;;;;;;;;;;;;;;;;;;;;lkkkkkkkkkkkkkkkkkkkkkkkkk0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.                   //
//                 .,;;;;;;;;;;;;;;;;;;;;;;;;okkkkkkkkkkkkkkkkkkkkkkkkkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0, .           ..    //
//                 .,;;;;;;;;;;;;;;;;;;;;;;;:okkkkkkkkkkkkkkkkkOOkkkkkkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,            ..'    //
//                 .,;;;;;;;;;;;;;;;;;;;;;;;;okkkkkkkkOkkxxddxxxxxxxxxxONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO'             ..    //
//                  .;;;;;;;;;;;;;;;;;;;;;;;;cxkkkkxxdoxO00KKXXXXXXXXK00KXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo.  .                //
//                  .';;;;;;;;;;;;;;;;;;;;;;;;okxdxkkk0NMMMMMMMMMMMMMMMMWNXXKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO'.....               //
//           .       .,;;;;;;;;;;;;;;;;;;;;;;;:oOKNK0NMMMMMMMMMMMMMMWMWWMMMMNXKXWMMMMMMMMMMMMMMMMMMMMMMMMMM0;.......              //
//     ..             .';;;;;;;;;;;;;;;;;;;;;ckNMMN0XMMMMMMMMMXxoxkkkOOOXWMMMMWKKNMMMMMMMMMMMMMMMMMMMMMMMWk,........              //
//     ..              ..,;;;;;;;;;;;;;;;;;;dXMMMMK0WMMMMMMMMM0:,coodkOOKWMMMMMMX0NMMMMMMMMMMMMMMMMMMMMWKl'.........              //
//                       ..',;;;;;;;;;;;;;:OWMMMMWKKMMMMMMMMMMWX0XNNXNXXNNNNNWWMMXKNMMMMMMMMMMMMMMMMMNOo,...........              //
//              ..         ...',,;;;;;;;;:OWMMMMMN0XMMMMMMMMWNXKKKKKKKKKXKKKKKKKKKO0NWMMMMMMMMMMMNKOo:'...............      .     //
//                       .........'''''',dWMMMMMMX0NMMMMNK00K0KKXNWWMMMMMMMMMMMMWX0dcldxkkkkkxxdl:,''''...............            //
//              .     ..................:KMMMMMMMX0WMNK00KXWMMMMMMMMMMMMMMMMMMMMMMMW0o;''''''....''''''''.................        //
//                 . ...................oWMMMMMMMK0K00KWMMMMMMMMMMMMMMMMMMMWWWNNWWWMMWKd;''''''..'''''''''....................    //
//                .....................'xWMMWWNNXOod0WMMMMMMMMMMMMMWNK0OkkkkxxxxxxxdxKKX0o,''''''''''''.......................    //
//              .......................';okkkkxxxdddxkOKXWWWNNXKOOkkxddxkkkOOOkxxkk:;xkk00x:''''''''''........................    //
//            ........................''.;xOOOOOOOOOOkxdxkkkdlloooodkOkkkkkOkdxkkkkl'',;lodd:''''''''''''.....................    //
//           ........................';;''ckOkkkkOOkkkkOOOOxdOXNNXKOxxOkkkkOdkNMMWKl'',,'',,,''''''''''''.....................    //
//      . ..     ....................';;'',lkOkkkkkkkOOOkOkdOMMMWMMM0xkOkkkkx0MMWWXl.''''''''''''''''''''.....................    //
//      ....     ...    ..........','..':dxxkOkOkkkkkOOOkOkd0MMWWMMMKxkOOkkkkONMMW0c..''''''''''''''''''..''..................    //
//    .......          ............,,'',okkkOOOkkOOkkkOkkkOxkXMMMMWXkkOkOkxddxk0KOkc..'''''''''''''''''''......,,.............    //
//    .......           .............'':dkOkkOOkkkOkkkOkkkkkkk0000OkkkOkkkxlcdkkkkx;.''''''''''''..'''''........'.............    //
//    .........         ...............:kOkkOOOkkkkkkkkkkdcloodddxkkOkkkkkxdxOOkkOo'.'...'''''''''.''''.......................    //
//    .....',;'.       ................'okkkkkkkkOOkkkkOkdlc:::llldxOkkxxxxkkkkkOk:.......'''''''''''''.................'''...    //
//    ...;ccl:''.   ....................':xkOOOOxdkOkkkOkkkxdddddxkkOkxddddkOkkkkl...........''''''''................'''..''..    //
//     .'cllc:::...................'...''.':cllc'.ckOkkkkkkkOOOOkkkkkOOOOOOOOkOkl'..........'''''''..................,c:;;'...    //
//     ..:dlclcol'.......................''....',,,;ldkOOkkkkkOOkkOOOkkOkkkkOkd;........'''''',''''................';,coll;...    //
//      .ckxxkdddolcc:;;,,;,''..''',,,,,,;;;;;:::::;;;:cloxkkOOOOOOOOOOOOkxdl:,',,'''''......''''''''..............:lcc:ol;...    //
//      ..cxkOOOkxkOOOkkkxxxddc';;::::::::::;;:::::::::,,'':llllllllll::::;,,;:::::;;:;;;,,,''''''''............';cdoodldx;...    //
//        ..;clooodxkkOOOOkkkOl,;;::::::::::;;::::::::::;;,;cloddoolc,'',;:::::::::;;::::::::;;,;lollllllllooddxxxddxkkkkd,...    //
//         ........',;:cclodxkc,;;::::::::::;;::::::::::::;;,,;;::;;,,;;:::::::::::;;::::::::;;;;oOOOOOOOOOOkkkkkkOOkkxo:'....    //
//    ...  .................','.,;;;;;;;;;;;;;::::::::::::::;;;;;;;;;;:::::::::::::;;::::::::;;;,lkkkkOOOOOOkxdoc::::,'.......    //
//    .'..    .............................';::::::::::::::::::::::::::::::::::::::;;::::::::;;;,cdddooollc:,'.....'..........    //
//     .       .........................'.';:::::::::::::::::::::::::::::;;;;;;::::,'',,,,,,,,,,'.'''.........................    //
//              . ........................'::::::::::::::::::::::::::::;,;cc:c:,;::,..........''..............................    //
//      .             ....................';:::::::::::::::::::::::::::,,lxxxxo,,;:,''.....'''''''............................    //
//    ......            ..................';:::::::::::::::::::::::::::,,ldlldl,';:,.......''''''''...........................    //
//    .''..             ...................;:::::::::::::::::::::::::::;,;c;;l:,;::,.''...''''''''''''........................    //
//     ....       .........................,:::::::::::::::::::::::::::::;;;;;;::::'.''.'''''''''''''.........................    //
//     ...'...  ...........................,:::::::::::::::::::::::::::::::::::::::'.'...''''''''''''''''''...................    //
//    .....................................,::::::::::::::::::::::::::::::::::::::;'.''''''''''''..........''.................    //
//    .....................................,::::::::::::::::::::::::::::::::::::::;'.'''''''''................................    //
//    .....................................,::::::::::::::::::::::::::::::::::::::;..''''''..................................     //
//    .    ................................'::::::::::::::::::::::::::::::::::::::,...............''..........................    //
//    .....................................'::::::::::::::::::::::::::::::::::::::,...........................................    //
//    ...     .............................'::::::::::::::::::::::::::::::::::::::,...........................................    //
//    .....   .............................';:::::::::::::::::::::::::::::::::::::'...........................................    //
//    .....................................'::::::::::::::::::::::::::::::::::::::'...........................................    //
//            ...  .............'..........';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;............................................    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Vinc3nt is ERC1155Creator {
    constructor() ERC1155Creator() {}
}