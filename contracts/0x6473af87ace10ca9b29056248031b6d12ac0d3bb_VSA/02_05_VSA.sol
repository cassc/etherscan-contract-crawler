// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Verasen Arts
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    ::::::::::::::::::::ccccccoxk00KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKd::c::::::::::::ccloddddddddddddddoolc::::::::::::::    //
//    ::::::::::::::::::ccc::codkO00KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXOc:cc:::::::::::ccloddddddddddddddoolc::::::::::::::    //
//    :::::::::::::::::ccc:cldxO000KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0lcl:::::::::::::cloodddddddddddddollc::::::::::::::    //
//    :::::::::::::::::ccccodxO000KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXOllc:::::::::::::ccloodddddddddddollccccccccccc:::::    //
//    ::::::::::::::::::clodxOOO00XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXkolc::::::::::::::ccllooddddddooollccllooooooollc:::    //
//    ::::::::::::::::::codxOOOO0KXXXXXXXXXXXXXXKKKKKKKKXXXXXXXXXXXKXXXXXXKOdlllc:::::::::::ccccllllooolllccccloodddddddoolcc:    //
//    ::::::::::::::::::lodkOOOOKXXXXXXXXXXXXKK00O00000000KXXXXXXKKKXXXXXXXXKklllc:::::::::ccccccccccccccc:ccloodddddddddoolc:    //
//    ::::::::::::::::ccloxOOOO0XXXXXXXXXXXK0OOO00OOOO00000XXXXXKKKKXXXXXXXXXXKxlc:::::cccccccccc::::::::::ccloodddddddddoolc:    //
//    :::::::cccccc:cc::coxOOOO0XXXXXXXXXXKOOkdddkOO000O000KXXKK0KKXXXXXXXXXXXXXOo:::ccllooollccc:::::::::cccllodddddddddollc:    //
//    :::::::::ccccccc::coxOOOOKXXXXXXXXXKOxooooddxkkOOOOO00000OkkkO0XXXXXXXXXXXX0o:ccloooooollcc:::::::ccllloooodddddooollccc    //
//    ::::::::::::ccc:::cokOOOOKXXXXXXXXX0xddxxkkkkkkkkkkkOOOOOOOkkkk0XXXXXXXXXXXX0ocllooodooolcc::::ccloodddxxddoolllllllllll    //
//    ::::::::::::::::::cokOOOOKXXXXXXXXKOkkkOOOOOOOOOOOOOOOOOOOOOOOkOKXXXXXXXXXXXXklcllooooollccc::cclddxxxxxxxxdolcccccllooo    //
//    ::::::::::::::::::clxOOOO0XXXXXXXXKOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0XXXXXXXXXXXXKxcclooddollcccccclodxxxxxxxxxxdlc:::cllooo    //
//    ::::::::::::::::ccccdOOOOOKXXXXXXXKxddddddxxkOOOOOOkkxdoooodddxOOKXXXXXXXXXXXXklloddxxddolcccccldxxkxxxxxxxxdlc:::cclloo    //
//    :::::::::::::ccccc:cxOOOOO0XXXXXXXOollllllloxOOOOOxolccclllllllodOKXXXXXXXXXXXOllodxxxxdolccccclodxxxxxxxxxdolc:::::ccll    //
//    :::::::::::cccc::::oOOOOOOOKXXXXXXKOOOkxxxxxkOOOOOkxxxkkOOOOOOkxdx0XXXXXXXXXXXOlcoodddddolcccccclloddxxxxdolcc:::::::ccl    //
//    :::::::::cccc:::::ck0OOOOOOKXXXXXX0olodxxxxxxkOOOOOkkkkkxolcc:::lox0XXXXXXXXXXKxccllolllccc:::::ccclloolllcc:::::::::cco    //
//    :::::::ccc:::::cloOK0OOOOO0KXXXXXXKc...:oodxxkOOOOkkdddc,.  ...  .,xXXXXXXXXXXX0o:cccccc::::::::::::cccc::::::::::::::cl    //
//    :::::::c::::cccokKX00OOOO0KXXXXXXXXOc;:ooclxkOOkOOkkdclol;,;cokdlld0XXXXXXXXXXXXkc:::::::::::::::::::::::::::::::::::::c    //
//    ::::::::ccccccdOKK000000KXXXXXXXXXXKkxxkxdxkkkkkkkkkkdxkkxxxxxkkOkkKXXXXXXXXXKKXKd::::::::::::::::::::::::::::::::::::::    //
//    ::::::ccc::coOKKK0000KKXXXXXXXXXXXXXOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk0XXXXXXXXK00XX0l:::::::::::::::::::::::::::::::::::::    //
//    ::::::ccloxOKKK0KKKKXXXXXXXXXXXXXXXX0kkkkkkkkkkkkkkkkkkkkkkkkkkkkkk0XXXXXXXXK0kOXXOc::::::::::::::::::::::::::::::::::::    //
//    ::::cldxk0KKKKKKXXXXXXXXXXXXXXXXXXXKOkkkkkkkkkkOOOkkkkkkkkkkkkkkkkk0XXXXXXXXK0dlkXXkc:::::::::::::::::::::::::::::::::::    //
//    :cldxkO0KXKKXXXXXXXXXXXXXXXXXXXXXXX0kkkOOOOkkxxxxxxxkkOOOOOkxxxxddxOKXXXXXXKK0o:cxKXOo::::::::::::::::::::::::::::::::::    //
//    oxOOO0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXkddxOOOOkxxddddddxkOOOOOxddddddkOKXXXXXXKKOl:::lk0Kko:::::::::::cccc:::::::::::::::::    //
//    OOO0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXOxddxkkxollccllllcllodxkOkxxxxxkO0KXXXXXXKKkc:::::ldkOOdl:::::::ccccc:::::::::::::::::    //
//    O0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0xdxkOkoldkO00KKKK00OkookOOkkxxkOO0XXXXXXXXKxlccccc:::lx00dc:::::::::::::::::::::::::::    //
//    0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXOxxkOOOOkk0KXXK0OOkkxxkOOOOOOkkOO0KXXXXXXKK0dllllllllc:cxKOl:::::::::::::::::::::::::::    //
//    0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKK0kxkOOOOOOOOOOkxxdxxkkOOOOOOOOOOO0XXXXXXXKXOl:::::::oo:ck0xc:::::::::::::::::::::::::::    //
//    KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKK0OOkkOOOOOOOOOOOOOOOOOOOOOOOOOOO0KXXXXXXXKKOl::::::col:d0kl::::::::::::::::::::::::::::    //
//    KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKK00OOOOOOOOOOOOOOOOOOOOOOkkO000O0KXXXXXXXKKKOo::::::oocdOxc:::::::::::::::::::::::::::::    //
//    kXXXKKXXXXXXXXXXXXXXXXXXXXXXXK0KK0000OkkOOOOOOOOOOOOOOOkkxxO000O0KXXXXXXXKOO0koc:::loldOxc::::::::::::::::::::::::::::::    //
//    cdOKKKXXXXXXXXXXXXXXXXXXXXXXXXK0KK0000kooxkOOOOOOOOOOkkxxxkO00OOOKXXXXXXX0olooddoc:lodkdc:::::::::::::::::::::::::::::::    //
//    c::lx0KKKXXXXXXXXXXXXXXXXXXXXXXK0K0000OdlllodxkkkkkkkOkxxxkO00O0O0KXXXXXXXkl:::ldo:cdkxc::::cccccc::::::::::::::::::::::    //
//    oc:::xK00KKXXXXXXXXXXXXXXXXXXXXXKK0000OdllllldxxxxkkOOOkxxkO00OO0O0XXXXXXXX0xolool::okdcclllooollcccc:::::::::::::::::::    //
//    cc:::dKK000KXXXXXXXXXXXXXXXXXXXXXXKK00OdlllloxxkkkOOOOOOkxkO0000000KXXXXXXXXXX00kdlccddccloddxxddolcc:::::::::::::::::::    //
//    :::lx0XK0000KXXXXXXXXXXXKXXXXXXXXXXXXKOdllloxOOOOOOOOOOOOkkO00000K00KXXXXXXXXXXXXK0Okxdoodxxkkkxxdolc:::::::::::::::::::    //
//    lxOKXXXK0OOO0KXXXXXXXXKKXXXXXXXXXXXXXXOolllokOOOOOOOOOOOOOkO00O000O0KXXXXXXXXXXXXXKKKKKkddxxkkkkxdolc:::::::::::::::::::    //
//    KXXXXXX0OOOOO0XXXXXXKKKXXXXXXXXXXXXXXXkollloxOOOOOOOOOOOOOOkOOO00OO0XXXXXXXXXXXXXKKKKKXKdloddxxxdddlc:::::::::::::::::::    //
//    XXXXXK0OOOOOO0XXXXXXKKKXXXXXXXXXXXXXXKxllllldOOOOOOOOOOOOOOOkkO000KXXXXXXXXXXXXXXKKKKXXkc:clloddddddlcc:::::::::::::::::    //
//    XXKK0OOOOOOO0KXXXXXXKKKXXXXXXXXXXXXX0kOkollloxOOOOOOOOOOOOOOOkkk0KXXXXXXXXXXXXXXKKKKXKdc:::cclodddxxolcc::::::::::::::::    //
//    K0OOOOOOOOO0KXXXXXXXXXKKKXXXXXXXXXXXKxd0kollloxOOOOOOOOOOOOOOOOOKXXXXXXXXXXXXXXKKKKXKkddoc:cclodddxxdolc::::::::::::::::    //
//    OOOOOOOO00KXXXXXXXXXXXXXKKXXXXXXXXXXXKOOxlllllxOOOOOOOOOOOOOOO0KKXXXXXXXXXXXXXXKK00OKNWWNKxlclodxxxdoolc::::::::::::::::    //
//    OOOOOO0KXXXXXXXXXXXXXXXXKKXXXXXXXXXXXX0xlllloxOOOOOOOOOOOkOOkO000XXXXXXXXXXXXXXKOkkOO0XNWWN0olddoddolcc:::::::::::::::::    //
//    OOOO0KXXXXXXXXXXXXXXXXXXKXXXXXXXXXXXX0dlllldkOOOOOOOOOOOOOOOOO0KKXXXXXXXXXXXXXXOxkOOOOO0XNNN0dlcllccc:::::::::::::::::::    //
//    OO0KXXXXXXXXXXXXXXXXXXXKKXXXXXXXXXXXKdllllokOOOOOOOOOOOOOOOOOOO0KXXXXXXXXXXXXXXOxkOOOOOO0KXNXkcccc::::::::::::::::::::::    //
//    OKXXXXXXXXXXXXXXXXXXXKK0KXXXXXXKKXXKxllllloxOOOOOOOOOOOOOOOOOOOkk0XXXXXXXXXXXXXK0OOOOOOOOO0XN0occ:::::::::::::::::::::::    //
//    OKXXXXXXXXXXXXXXXXXK0000KXXXXKkkKXKklclllllokOOOOOOkOOOOOOOOOOxoclOXXXXXXXXXXXXXXK00OOOOOOO0KKdcc:::::::::::::::::::::::    //
//    O0KXXXXXXXXXXXXXK0OOOOOOKXXXKdoKXXklcccclllodOOOOkkkkOOOOOOxdoc:::lx0XXXXXXXXXXXXXXXKK0OOOOO00xlc:::::::::::::::::::cccc    //
//    000KXXXXXXXXXX0OOOOOOOO0XXXX0dkXXKo::::::cclldkOOkkkkOOOOkoc:::cccllodkOKXXXXXXXXXXXXXXK0OOOO0klc::::::::::::::::::ccccc    //
//    K000KXXXXXXXK0OOOOOOOO0KXXXXKOOKXKdccccc:::cclodkOOOOOOkdlccccclllllllllo0XXX0OOKXXXXXXXKOOOO0Ooc:::::::::::::::::cc::::    //
//    XK000KXXXXXKOOOOOOOOO0XXXXXXXXOkk00xolllccccccclodxkkkdlcclllllllllllllokKXXOoccokOKXXXX0OOOO00dcc:::::::::::::ccc::::::    //
//    XXK000KXXXKOOOOOOOO0KXXXXXXXXXX0xooddddolllllllllloodolllllllllllllllloOXX0xllcccoxk0XK0OOOOO00o:::::::::::::::cc:::::::    //
//    XXK0000KXKOOOOOOOO0KXXXXXXXXXXXXXKkdooldxollllllllllllllllllllllllllllkXX0dlllcccldOKK0OOOOOO00o::::::::::::::::::::::::    //
//    XK00000KX0OOOOOOOOKXXXXXXXXXXXXXXXXKOkkxxdlllllllllllllllllllllllllllldOK0dllllcccdOOOOOOOOOOOOo::::::::::::::::::::::::    //
//    K00000KXX0OOOOOOO0KXXXXXXXXXXXXXXXXXkdk0Odlllllllllllllllllllllllllllllldxxxdolc:lodxkOOOOOOOOOd::::::::::::::::::::::::    //
//    00000KXXX0OOOOOOO0KXXXXXXXXXXXXXXXXXOook0kolllllllllllllllllllllllllllllllloodoccollxkOOOOOOOOOd::::::::::::::::::::::::    //
//    000KXXXXXKOOOOOOOOKXXXXXXXXXXXXXXXXXkoodkOdllllllllllllllllllllllllllllllllllccccol:oxOOOOOOOOOxc:::::::::::::::::::::::    //
//    0KKXXXXXXX0OOOOOOO0XXXXXXXXXXXXXXXXKxolldkdlllllllllllllllllllllllllllllllllcc::cll:cdkOOOOOOOOxc:::::::::::::::::::::::    //
//    KXXXXXXXXXKOOOOOOO0KXXXXXXXXXXXXXXXOdlllokdlllllllllllllllllllllllllllllllllcc:::cc::lkOOOOOOOOxc:::::::::::::::::::::::    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VSA is ERC721Creator {
    constructor() ERC721Creator("Verasen Arts", "VSA") {}
}