// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cana Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNXK0OOkxddoollccccccccllodxkO0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0OOkkxxxxxxddddoooooolllllcccccccloxk0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWNXK0Okkkkkkkkkxxxxxdddddddddoooolllllllllllllodk0XNMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWXK0OkkkkkkkkkkkkkxxxxxxxxdddddddoooooooooooooooooooodxOKNWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWX0OkkkkkkkkkkkkkkkkkkxxxxxxxxddddddddooooooooooooooooooooodxOXWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWNKOkxxxxkkkkkkkkkkkkkkkkkkxxxxxxxddddddddooooooooooooooooooooooodk0NWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWNKOxxxxxxxxxxxxxxkkkkkkkkkkkkxxxxxxddddddooooooooooooooooooooooooooooxOXWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMNKOkxxxxxxxxxxxxxkkkkkkkkkkkkkkxxdddddooooooooooooooooooooooooooooooooooxKWMMMMMMMMMMMMM    //
//    MMMMMMMMMMWXOkkxxxxxxxxxxxxxkkkkkkkkkkkkkkxxxdddoooooooooooooooooooooooooooooooooodONWMMMMMMMMMMMMMM    //
//    MMMMMMMMMN0OkkkkkxxkkkkkkkkkkkkkkOOkkkkkkxxxdddooooolllllllllllllllloooooooolloodOXWMMMMMMMMMMMMMMMM    //
//    MMMMMMMWXOOkkkkkkkkkkkkkkkkkkkkkOOkkkkxxxdddooollllccccccccllllllllllloooolllodkXWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMNKOkkkkkkkkkkkxxxkkkkOOOOkkkkkxxdddollc::;,,,,,,,,;;::cccccllllllloooookKWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMN0kkkkkkkkkkkkkkkkkkkOOOOkkkxxxdooc:,'.................',;:ccclllllllokKWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMN0kkkkkkkkkkkkkkkkkkOOOOkkkxxddoc;'.........................';:ccclloxKWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMN0kkxxxxkkkkkkkkkkkOOOOOkkxxdolc,...............................,;:cd0NMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMN0kkkxxxxxxxkkkkkkkkkkOOkkxdolc::,''','......'''''''',,''..''......;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MWKOkkkxxxdxxxxkkkkkkkkkkkxxdocccccclc;,...',,,;,,;:::cc;;;'',;,''....c0WMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MN0kkkxxxxxxxxkkkkkkkkkkkxddl;'''.';,....',,;:c:;;:cllllcc:,;::,,,'....,kNMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    WKOkxxxxxxxxxkkkkkkkkkkkxddl,..........',,,;::c:;:ccc::ccc:::cc::;,'....'xNMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    XOkkxxxxxddxxkOOkkkkkkkxdol,..........',::c:;;;:;;;;,,;:::clllllc:;;,'...'xWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    KkkkxxxxddxxkkOOkkkkkkxdol;...........,:::c:;,,.........,cooooollccc:,'...;0MMMMMMMMMMMMMMMMMMMMMMMM    //
//    Okkxxxxxxxxxkkkkkkkkkxxdoc'.........',:cc:c;'..         ..,cooooolcc;,''...oNMMMMMMMMMMMMMMMMMMMMMMM    //
//    kxxxxxddxxxxxxkkkkkkxxdol;...........',;cc:'.             ..;looooc;,''....;0MMMMMMMMMMMMMMMMMMMMMMM    //
//    xxxxxxddxxxxxxxkkkkkxxdol,.........',,,,;;'..               .:oodlc:;'.....'OMMMMMMMMMMMMMMMMMMMMMMM    //
//    xxxxxxxxxxxxxxxxkkkkxxdol,..........,::::;'.                .;odool;''.....'kMMMMMMMMMMMMMMMMMMMMMMM    //
//    xxxxxkxxxxxxxxxxxkkkxxdol,.. .....,;::::;,..                .;oddl;''......,OMMMMMMMMMMMMMMMMMMMMMMM    //
//    kxxxxxxxxxxxxxxxxkkkkxddl;. ......',:;;;;;'.               ..cool:;''......:KMMMMMMMMMMMMMMMMMMMMMMM    //
//    kxxxxxxxxxxxxxxxkkkkkxxdo:........',;;;;::;'.             ..;ool:,,,'......oNMMMMMMMMMMMMMMMMMMMMMMM    //
//    Oxxxxxxdddddddxxxxkkkkxdol,......',,,;:::::;,..         ..,:lol:,,'.......:KMMMMMMMMMMMMMMMMMMMMMMMM    //
//    Kxxxxdddddddddxxxxxkkkxxdoc'......',;:::;:c:;;;'.......';:llcc:;,,''.....,OWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    Xkddddddddddddxxxxxxxxxddol:.......',;;;:clcclc:;::cc::cccc:;,,,''''....,kWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    W0dddddddddddddxxxxxxxxddolc;'.....''',;;::clc;,;clllc::;;;;,'''''.....:0WMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MXkdddooooooddddddxxdddddoolc;'.......',,,,:c:,,:::clc:;,,,,''''.....;dXMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MWKxooooooooodddddddddddooollc:,..........',,,,,,'',;;,,','''.......,xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMW0dooooooodddddddddddddooollc::,..........''''.'''''''''.........',cxKWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMN0dddddddddddddddddddooooolllcc:,'.............'..............',;;::lkXWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMW0xdddddddddddddddddoooooolllccc::;''....................',,;;::::c:clkXWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMW0xddddddddddoooooooooooooollllccc::;;,,,'''''''''',,,;;;;:::cccc:::::lkXWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMWKkddddddddddoooooooooollllllllccccc::::::;;;;;;;;:::::::cccccc::::::::lkXWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMNOxddddddddooooooooooolllllllllcccccccccc:::::::cccccccccc::::::::;;;;;ckXWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMWKkddddddooooooooooooooollllllllccccccccccccccccccccccccc::::::;;;;;,,,;ckXMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMN0xddddoooooooooooooooolllllllllllccccccccccccc:::c::::::::;;;;;,,,,,,,;lkNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWN0xdooooooooooooooooooollllllllllllllcccccccc:::::::::::;;;;,,,,,,,,,,,cOWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWN0xdoooooooooooollllllllllllllllllllcccccccc:::::::;;;;;;,,,,,,,,,;cxKWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNKkdooooooololllllllllllllllllllccccccccc::::::;;;;;;;,,,,,,,,:oOXWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWX0kdooooolllllllllllllllllllcccccccc:::::::;;;;;;;,,,,,,:lkKWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWXKOxoolllllllllllllllllccccccccc::::::;;;;;;;;,,,;cokKWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWNX0kxdolllllllllccccccccccc:::::::;;;;;;;;cldk0NWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0Okxdollccccccccccc:::::::::ccldxk0XNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKOkxdollccc::::ccclodxk0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CANAED is ERC1155Creator {
    constructor() ERC1155Creator() {}
}