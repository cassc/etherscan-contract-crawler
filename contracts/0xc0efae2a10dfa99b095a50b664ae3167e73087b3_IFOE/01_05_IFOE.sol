// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IMAGINED FUTURES - OPEN EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    cccccccccccccccccccccccccccccc:ccccccccccccccccccccccccccccccccccccccccccccccc:ccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccc:ccccccccccccccccccccccccccccccccccclcccccccccccccccclcccccccccccccccc    //
//    cccccccccccccccccccccccccccccc:ccccccccccccccclc:ccccclcccllcccccclcc::ccccclc:lllllccclcccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccclllccclllc:lllcclcclll::cc:;;ccc::cclllcclllllccclcclclllccccc    //
//    ccccccccccccccccccccccccccclllcclccccllllccllllc:ccccc:clcclc:c:;'',;:;ccc::cc:lccllccllccllllllllll    //
//    ccccccccccccccccccllllllllllllcclccccllcc::cc:c::ccc:::;::::;;,.''....',,,::::clc:lllcllccllllllllll    //
//    cccccccccccccllllllccclcllllllc:cccc:ccc,.......'....''...................':looolloollllccllllllllll    //
//    llcclllllllllllllllccllccllcccc;;,;'.'''...................................':oooooddooooloolllllllll    //
//    llllllllllllllllllc:::;,;;:::,...................'',;;:clodxkO000o. .......':ooclooooooooodollllllll    //
//    lllllllllllllllc;''...................'',:clodkO0KXXNWMMMMMMMMMMMX: .......':ol;;::cllllooddolllllll    //
//    llllllllllllllc'..........',;:clodxO00KXNWMMMMMMWNNXK0OkxdxNMMMMMX: .......':oc,,,,;::;,;lodolllllll    //
//    llllllllllllll,.....cdxO0KXNWMMMMMMMMWXK0Okxdoolc:::;;;;;;lXMMMMMX: .......':ol;;::cc::;,cddoooooooo    //
//    llllllllllllol,.. .xWMMMMNKK0Okxd0WMMk,,;;;::cclooodddxxxxONMMMMMX: .......':oc,;clooool:codoooooooo    //
//    lllllllllloool,.. .OMMMMXl';;::ccOWMMx':dxxxxxxxxkkkkkkOO0KWMMMMMN: .......':oc,,;;;::cl:codoooooooo    //
//    oolooooooooool,.. .OMMMMK:.:oxxxkKWMMk,cxkkkxk0KKXXXNNNWWMMMMMMMMNc .......':ol,;:;;,,,;;coddooooooo    //
//    oooooooooooool,.. 'OMMMMK:.:dxkkkKWMMO;cxkkkxONMMMMMMMWNXNMMMMMMMNc .......':ol;colccc:c:coddooooooo    //
//    oooooooooooool,.. .OMMMMX:.:dxkkkKWMMO;cxkkkxkKX0xdoollcckWMMMMMMNc .......':ol;dOkxxddoccoddddooooo    //
//    oooooooooooodl,.. .OMMMMK:.:dxkkkKWMMO;cxkkkkkkxdlllloddxKMMMMMMMNc .......':oc:dOkOOOOOocoddddddddd    //
//    oooooooooooodo,.. .OMMMMX:.:dxkkkKWMMO;cxkkkkkkkkkkkxxxxkKMMMMMMMNc .......';oc:dOkkkOkxlcoddddddddd    //
//    oodddddddddddo,...'OMMMMX:.:dxkkkKWMMO;cxkkkkkkOO000KKKXXWMMMMMMMNc........';oc:x000KKK0ocoddddddddd    //
//    dddddddddddddo,...,0MMMMX:.:dxkkkKWMMO;cxkkkxOXWWMMMMMMMMMMMMMMMMNc .......';occxK0KKKKKdcodxxxxdddx    //
//    dddddddddddddo,...,0MMMMK:.:dxkkkKWMMO;cxkkkxONMMMMMMMMMMMMMMMMMMNl .......';ol:oxkO00KKdcodxxxxxxxx    //
//    dddddddddddddo,...,0MMMMK:.:dxkkkKWMMO;cxkkkxONMMMMMMMMMMMMMMMMMMNl........':ol;;:clloddlcooxOkkkxxx    //
//    xxxxxddddddddo,...,0MMMMK:.:dxkkkKWMMO;cxkxkkONMMMMMMMMMMMMMMMMMMNl........':lolccc::::::codkOOOOOOO    //
//    kkkkkkkxxxxxkd;...,0MMMMK:.:dxkkkKMMMKdk0KXXXNWMMMMMMMMMMMMMMMMMMNl .......';loooollllccloodkOOOOOOO    //
//    xxxkkkkkkkkkOx;...,0MMMMXdlx0KXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXd.  ......';col;,,,;::cloookOOOOOOO    //
//    xxkkkkkkkOOOOx;...'OMMMMMMMMMMMMMMMMMMMMMMMWWNNXKK00OOkxdoolcc:;'.   ......';ll;.........:ddxOOOOOOO    //
//    OOOOOOOOOOOOOk;....xWMMMWWNNXKK0OOkxdoollc::;,''.......            .........;oo;''','',..,odkOOOOOOO    //
//    OOOOOOOOOOOOOk;.....:cc::;,,'......         ............      ..............;lll;',,',,..:ddkOOOOOOO    //
//    OOOOOOOOOOOOOk;....    ..........  ......................     . ............,clllollccc;:oddkOOOOOOO    //
//    OOOOOOOOOOOOOk;................                                ..............,::::ccloooooodkOOO0000    //
//    OOOOOOOOOOOOOk;..............                                      .............''',;::cclloxO000000    //
//    OOOOOOOOOOOOOk:.......  .                                                .............'',,;oO0000000    //
//    OOOOOOOOOOOOOOx,........,,..                           .    .    ..     .....,;;;;c;..'';:ok00000000    //
//    OOOOOOOOOOOOOOOkc;:::clc:ldl..    .                   ...  ..    ..........':xxkxoOxcoxxkO0000000000    //
//    OOOOOOOOOOOOOOO0OkOOOOOdlokOl.  ....                 ....      ...........cdx0O0kxOkdO0OO00000000000    //
//    OOOOOOOOO0000000OOOOO00kddO0x'  ....                 ....  . ...........'okkO000Ok0OxO00000000000000    //
//    OOOOOOOO000000000O00000kxOO0o.  ....  . .   .        ...  ........''..',lO000000OO00O000000000000000    //
//    00000000000000000000000kO000d....... .. ..  ..   .   ...  .......;l:,;cldkxO00000O000000000000000000    //
//    00000000000000000000000O0000Olc;....... ..  ..  .. .....  .......:oc;clldolk000000000000000000000000    //
//    00000000000000000000000000000xko,'..... ..  .  ... .............'clccllldkO0000000000000000000000000    //
//    00000000000000000000000000000O0xdd'.... ..  .  .................;l:;cc;:clO0000000000000000000000000    //
//    0000000000000000000000000000000kkk:.... ...... ... ..........''.:o:;cc,,;cO0000000000000000000000000    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract IFOE is ERC721Creator {
    constructor() ERC721Creator("IMAGINED FUTURES - OPEN EDITIONS", "IFOE") {}
}