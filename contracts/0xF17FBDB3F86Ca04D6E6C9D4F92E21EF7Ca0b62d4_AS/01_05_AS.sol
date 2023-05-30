// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: abdllhart.III
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNNNNXXKKKKKXXNNNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX00OkkOOOOO000000KKKKKKKKKKXNXXNNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKkddddddk0XNWWMMMMMMMWNXKNWWWWNXXXXXK00KNWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdddddddxxkKNWMMMWNXKOdl:,,cx0NWNKKXXNWWNKKKXNNWWWWWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMNX00xolodddooodxOKNMMMXOd;.''.....,lkKXKXNXNWWMWNKKXNNXXXXNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWNKOkxxO0kdooddooooollxNMMKd;.',,;,''....,cloONWWMMWWWWXKXNWWK0NMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWX0kxxxkOOKX0Okxxxocc;''':OMMOl,.',,;::,'.......'dXWMMWXXNX0OO0XX0XWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWN0kdodkO00KXXNX00kxxdl;'';;,:kXk;'.'',,;;,........ 'dKWMWXXKXNWKxkNWXXXWMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWNKOxddxkOKXNWWWWWWWW0O0OkdcoOkl;,lc,,...,............ ..l0WWNNNNWMWX0OKNNXKXWMMMMMMMM    //
//    MMMMMMMMMMMMWKkdoodxxk0KXWWMMMMMMMMX00KXKOKW0olc::c:,....  ...    ...  .:k0XNWNNWWWWNXOOXNKOKWMMMMMM    //
//    MMMMMMMMMMWKxl:cldddxOKNWMMMMMMMWMMNK0k0KKXW0doo:,,,;;,,'..........''';lxd:d000KKKXNNNXOxkxcc0MMMMMM    //
//    MMMMMMMMW0dol:::ldddkKXWMMMMMMNXKKXKXNXKKKXX0xxxd;.;c::c:;;,,;::;::cxKXX0kdxKKkxxox00KXKdoxl;xWMMMMM    //
//    MMMMMMMNkoooc:::loxxOKXWMMMMWX00KXNNWMMWXKXN0xkkxoldO0kdocloll:;;;,';okdcdOKN0O0OdoddllkO0X0oOWMMMMM    //
//    MMMMMN0dlddlc::cloxkkOKWWMWX0OOXWMMMMMMMWNWXOxkkkxkdONWNXK0kxoc:ccldocdxld0KXOxkkdlxOo;cdkKWWWMMMMMM    //
//    MMMMNklcoolcc:::codkOOKXWMXkkO0XWMMMMMMMWN0kxxkkxxkkOKX0kxxdxxdl:c::lxooolx0kxdooO0KWW0ocx0XWMMMMMMM    //
//    MMMWOlcolcllc::;:lokOO0KNW0ooxOXWWWMMMMXkodOOkxkO00OOkxkkOOOkxxo:,''::;clccc:lodd0WMMMMNkld0WMMMMMMM    //
//    MMMKo:lllcllll:;;;coxk0XX0oloodOKNNNXX0lcoxd::x0klc;cxO00Okollcll;'.;::oxkxox0kdkNMMMMMMWkokXKKWMMMM    //
//    MMNx:clclllllc:,,:cldkkOko:cloddkOOkkx:;::;',d0Ol,;,'cxkxodkO0KXX0d;;coolxkoOWWWWMMMMMMMMNxkXdoKWMMM    //
//    MMWx;;:clccolc:;,:loxxooo::cclodxxddxl;;:cc:l0N0l::,'';dkkKWMMMMMMW0loOOooOXWWMMMMMMMMMMMWXXNdoONMMM    //
//    MMMXl,;clccoxdolclddoc,,;:llcc:cldxkxolccdxdxXKdol;;:c:;lkkONMMMMMMMWWWWXXWMMMMMMMMMMMMMMMMMXdlxKMMM    //
//    MMMMO:'''',;cllccol:,'''';clldkO00OxoloodxdkO0Odl:;coolc,cxxxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0lodOWMM    //
//    MMMMWXOo;,;cllcc:;;,''',,;lxkdl::cokkdxxddodkkdl;;:loc:;::ckkdOWMMMMMWWMMMMMMMMMMMMMWWMMMMMXxdxdoKMM    //
//    MMMMMMMN0c';coooolc:::clx0NNO:'....:oodkxdodXXd:;clc::;,;::cxOdxKWMMNOkNWNKXMN00NMMXxOWMMMXxxOOl;kMM    //
//    MMMMMMMMWO'.':cc:;;:;,,cd0KxolllcldkOxldOxkKWNOl;:ccllc:;,clckXklxXN0okXXXOOKkdOXKkooxkKKkdooollo0MM    //
//    MMMMMMMMWXl.',;,..','.,oxkxlodxkO0XWWKxkkddk0KNKdc:cloooc;:lclOXOloOxlONWW0dxxdkxoloddoxxoodddooONMM    //
//    MMMMMMMMMMNK00l''',;,,oOkk0XK0kOXWMMNOkXWX0OOOO00Okxoodoc:;:cllkXXkxxxkOOkdoddodooddxkOKOxkOdllkXMMM    //
//    MMMMMMMMMMMMMM0;';:::,:ddlokKXNWWWX0k0NMMMMMMWNX000K0OOOOkollxO00KXNNXNNK0KK0OOO00K0kkXXkdodxkKWMMMM    //
//    MMMMMMMMMMMMMMWOllldxxOKKOxxxxkO00OOKWMMMMMMMMMMMWWNKOxxk00OOOkkddxOXNWNNWWWXXNNNNNX0OOxllxKWMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWWMMMMMMMWNXKKXXNWWMMMMMMMMMMMMMMMMMMWX0OOkxollc:clldxxkKXX000kdoddxdxxOXWMWMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNXK0OOkkxdddxkxdddxO0XNWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKXXXXNWMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AS is ERC1155Creator {
    constructor() ERC1155Creator() {}
}