// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shiba Wings
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWWMMMMMMMMMMMM    //
//    WWWWWWWNNXXKKKK0KNWMMMMMMMMMMMMMMMMMMMMMMWWWNKKK0KXXXKXNWMMMMMMMMMMMMMMMMMMMMMMMMWNKOOKKXXNNNWWWWWWW    //
//    WNXXNNWNX0OOOOOkkkKWMMMMMMMMMMMMMMMMNKKNKkOKkoxkdk0kxdxxONWNXNWMMMMMMMMMMMMMMMMMN0kkdxOOOOKNWNNXXXNW    //
//    MMWWNXXXKK00OOOOkxdONWMMMMMMMMMMMMMNxld00xdkkxkkdk0xooookKOdoxXMMMMMMMMMMMMMMMWXkdxxdkOO0KKXXXNNWWMM    //
//    MMMWWWNNXXNXK00kxxoldONWMMMMMMMMMMMW0xox0OkKNKXXXXNK0OOO0kddoxXMMMMMMMMMMMMMWXkoldxox0KKXXXNNWWWMMMM    //
//    MMWNXXKKK000OkkdcloolldkKXWWMMMMMMMMWKkONWWWMMMMMMMMMMMMWNXOx0WMMMMMMMMMWNX0kollolc:okO00KKKKKXNWMMM    //
//    MMWWNNXKKKKKK0Okoc:coxxdddk000KKKKKXXNNWMMMMMMMMMMMMMMMMMMMWNNNXXKKKKK0OOxdodddolcclxO0KKKKKXXNWWMMM    //
//    MMWWNNNNNNNXXK000xolodxkkxkO000000OOOO0KNWWMMWWNXXXNNWMMMWWX0OkkkkOOO00kxxxkkkxxdook0KKXXNNNNNNWWMMM    //
//    MMMMMMWWWNNNNXXXKOkkkxxkO0OOkOkkkkxxxxdxkOKKkdlc:::ccoxOKKkddddxxxxxxxxxk00Okkkkxdd0XXNNNNWWWMMMMMMM    //
//    MMMMMMMMMWWNNNXXK0O0KK00OkxdkOOkxxdoollllllol:,,,,,,,;collcccloddxxxxkxddkkO0KKKkdkKXNNNWWMMMMMMMMMM    //
//    MMMMMMMMWWNNNNXXK0kxxkkkxdoodkOkkxdollc:;:ccdOkxxkkkxkkl;::;:clodxkkkkdooodkkkkdlx0KXNNNNWWMMMMMMMMM    //
//    MMMMMMMMMMWWWNNXKK0kxdxkkkxdoxOkkxxdoolc::clx00kxxxxk0Odl:::lodxxxkkkdodxkkkxdoodOKXXNNNWWMMMMMMMMMM    //
//    MMMMMMMMMWWNXXXKKKK0kddxkkxdloxkdooooolccloloodoooooooollllclodxxkkxddoodxkkdllx0KKKXXXNNWMMMMMMMMMM    //
//    MMMMMMMMMMWWNNNXXK000Okkkxxxxxxxxkkxdooooolc;,:looooc:,;cllooooxkkkddkkxxxxkxdxO0KKXNNNWWMMMMMMMMMMM    //
//    MMMMMMMMMMMMWWWWNXXKXKKOxdxkkddxxxxddxxxdlll:;cxkkkkdc;cllldkxxdddddddxOkxoox0XXXXNNWWWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWWNNXK0Okxxddxkkxlcloxxdccloddxo:;;;odooolloxkdolcokkxdddodxO0KXNWWWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWWNXKKK0Okddxkkkxocldlloooodool;,,;loddooooooocldkOkxdooxO0KKXNWWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWNXKKK0K00000OxddxkxddolloxdoodkOkxxk0OxddxdlllodxOkxdodk0000KK0KKXNWWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWXKKKKKKKKK0Okxxxkkxdddoddooc;;clooool:;:looooddxdxxdddxk00KKKKKKKKXNWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWWNNXXK000000000OkxxkOk0K0OkxxxxxxkO00OkkxxxxkO0000000KKXNNWWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWWWNNWWNXXXXXXXXNNNXXNWWMMMWMMWWWNKXNNXXXXXXXXXNNNNNWWWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0dxOOkO00OkxOkxdxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXOkOkddxxdoxOOO0KNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNKKXNXXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SW is ERC721Creator {
    constructor() ERC721Creator("Shiba Wings", "SW") {}
}