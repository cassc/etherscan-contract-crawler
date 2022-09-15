// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Carres by Kipz
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMXOkkkkkkkkkkkkkkkkkkkkkKWKOkkkkkkkkkkkkkkkkkkkONNK000000000XWWN0ONMWNWWXOKWWNNWNXXKXXKXKXKKXKXKXKKXKXKXXKXKXXKXKKXWMM    //
//    MMWKxc,'''''''''''''''',:ckWk;,'''''''''''''''',lxxocccccccoxkkd0Kc;OWX0XNx;oXNKKNXxxdxxxxdddxxdxdxxxxdxdxxxxddddxddkXMM    //
//    MMXxdOxc,'''''''''',:dk0KKXXK0Oxc,''''''''''',lxkocccccccokkxo,,kXdo0WNXNWOlxNNXXWXkdxxdxxxxdxdxxxxdxxxxxxdxxxxdddxxkXMM    //
//    MMXdcldOxc,''''''':xKXK00000000KKOc,''''''',lxkocccccccokko;''',kKl:OWXKXNx:oXNKKNXkdxxdxdxxxxdxdxxdxdxxxxxxdxxdxdddkNMM    //
//    MMXdcccldOxc,''''c0X0000000000000XKo''''',lxkocccccccokko;''''',kXdo0WNKNWOlxNNKXWXkdxxxxdxdxdxxdxdxxdxdxxxxdxxxxxxdkNMM    //
//    MMXdcccccldOxc,',kX000000000000000X0:'',lxkocccccclokko;''''''':OKolOWXKNNkcdXNKKNXkdxdxxxxxxdxxxxdxdxxdxdxxdxdxdxxdONMM    //
//    MMXdcccccccldOkcc0X000000000000000XN0kkOXX0OOO00000ko;''''':ldOKXNXXXNNWWW0dkNKxkXXxdxdxdxddxdxddddxdddxxdxdxddxdxddkXMM    //
//    MMXdccccccccclxOOXX000000000000000XXxddddddddddkK0o,''''',oKWNXK0000000KXN0kONXkkXX00K0K0KK0K0K0K00K0K00K00OOO000K0KXNMM    //
//    MMXdccccccccccclx0NX0000000000000KXklccccclccokko;'''''',xNNXK000000000000XNWW0kxxkxkXXxook0xooooo0NXNWXOxdooodxk0NMMMMM    //
//    MMXdccccccccccccclx0KK000000000KXKxlcccccccokko,''''''''lXNK000000000000000KXNNOocccl00;'':kl'''''xNXKkoccccccccclkNMMMM    //
//    MMXdcccccccccccccccldO0KKXKXKK0Oxlcccccccokko;''''''''''oNN0O00000000000000KKKXNXkoco00:'''dx,''''xWXxccccccccldkkxdOWMM    //
//    MMXdcccccccccccccccccclodx0W0olccccccccokko,'''''''''''.:KNKO0000000000000KKKXXKXNKxo00:'''ckc''''xW0lcccccoxkkxo:,.cKMM    //
//    MMWKOOOOOOOOOOOOOOOOOOOOOOXWX000O00O000XXOkkkxkkkkxkkkkxkXWNXK000000000000KXXKKXXKXXKX0:''',xd''''xWOlcldkkxdc,'''''cKMM    //
//    MMWXKKKKKKKNMNklkNNklllllo0NOxxxxxkXMNNX0KNNNK0NNNK0NNNX0XNNWNXK00000000KXXKXNXKXNXKXWKl;;;;dOc;;:kWXkkkxo:,''''''',dNMM    //
//    MMWNX0kxk0XWMNklkNNo''''''xXdcccccl0N0kOOOOkOOOOOXN0OkkOOOkkOOKNXK0KXKKXXXNWXKXKNNK0000OkkkkOO0KK0KXXXk;'''''''''';xNMMM    //
//    MMMXdodddooKWWNXNWNo''''''xXdcccccl0Kc'''''''',ckkl,'''''''''';o0NXKKXXKXNWNxllldOOl;,,,,,,,;lONN0xdx0XOo:;,'',;cxKWMMMM    //
//    MMNoc0XKXKlcXWXKXWNkccccclONOdxxxdxKKc'''''',ckXXkxxxxxxxxxxxxxxONWWXKKXXKNNxccccldkxl,''',ckKKXXo''':ONXK00OO0KNWWWWMMM    //
//    MMNoc0NKXKlcKW0x0WWKkkkkkkKNOdddddxKKc'''',ckOkxxxxxxxxxxxxxxxxxxxxkXNXKKNWNxcccccccdkxc;ckKK00XXl''':OWXXXXKKK0000KXWMM    //
//    MMMKdldddoo0WNd:dNNxccccccOKc.'''.,kKl;;;lk0kooooooooooooooooooooooldONWXXNNxcccccccccx0KKK0000XW0xxkKNXK00000000000KNMM    //
//    MMMWXK0OkxONMMNKNWNkccccccOKc''''',ONkdkKXNXX0xxKXKKXKOxOXXKKKX0xxKXKKNW0kKNxccccccclx0KK000000XKdo0NXK0000000000000KNMM    //
//    MMWX0XWM0::OWWX0XWWkllllllOXl,,,,,:OXo,dNX0XWO;:0NK0NXo,dNX00KWO;:0NK0NXl,xXxccccclx0KK00000000XNXKkcckKK00000000000KNMM    //
//    MMMNKKXXK0KXKKK0KKKOkk0KKKNNK00000KNWXKXWNNNWNO0WWNNWWXKXWWNNNWNKKNWNNWWXKNNxccclx0KK0000000000XWWO;'',ckKK000000000KNMM    //
//    MMW0ollok0x:,;;;;,;,;oOkdkXWNNNNNNNNNNNNXNNNWKldNWNNNNNNNNNNNNNNNNNNNNNNNNWNxclx0KK000000000000XWKc''''',ckKK0000000KNMM    //
//    MMMXdlxOx:'''''''',lxkdk0OxkXWNNNNNNNWKl:kNNWKcoNWNNNNNNNNNNWWWWWWWWNNNNNNWNxd0KK00000000000000XWk,''''''',ckKK00000KNMM    //
//    MMNXKOd:'''''''',cxkxxKNNWXOxOXWWWWWNWXOxKWNWKcoNWNNWWWWWWWNXXK000KXNWWWNWWWNNNXXXXXXXXXXXXXXXXNWd'''''''''',ckKK000KNMM    //
//    MMNXXd'''''''''cxkxxKNNK0KXWXOxkXWWWWWWWWWWWWKoxWWNWWWWWWWKdollccccldOXWWWWWWWWWWWWWWWWWOldKNXXNWx,''''''''''',ckKK0KNMM    //
//    MMMXXk;'''''':xOxx0NNK00000KNWXOxOXWWWWWWWWWWXxkNWWWWWWNkokkkdcccccccco0WWWWWWWWWWWWWWWW0odXWXXWM0:''''''''''''',ckKXWMM    //
//    MMNXKKl'''':xOxx0NNX000000000KNWXOxOXWWWWWWWWKcoNWWWWWWk,',ldkkdcccccccl0WWWWWWWWW0kkkkkkkk0KKNWWNd,'''''''''''''',cONMM    //
//    MMNXKXk;':xOkdkXWWNXXXXXXXXXXXNNWNKkdONWWWWWWKcoNWWWWWNo''''',lkkdlcccccxNWWWWWWWNxccccccoxxclXWWWNd,''''''''''''''':KMM    //
//    MMMXKKKxxKKxdxkkkkOkkkkkkkkkkkkkkkkkxdkKWWWWWKcoNWWWWWNd''''''',lkkdcccckWWWWWWWWNxccccoxdc,.cXWWWWNO:'''''''''''''':KWM    //
//    MMNXKKXNWNXNNNNXNNNNXNXNNNNNNNNNNNNNNNNNWWWWWXxOWWNWWWWKc'''''''',lkkdldXWWWWWNNWNxcloxxc,'''cXWWWWWWXxc,''''''''''':KMM    //
//    MMNXKKKKXKKXKXKXNNNXKXXNWNNNNNNNNWNNWWNNNNNNWXodNWNNNNWWKd;'''''''',lOKXWXKKKKKKNNkoxxc,'''''cXWWWWWWWWN0xl:,''''''':KMM    //
//    MMMXKKKXXXXKKKXNXKNXKKXWWNNNNNNWKdlldKWNNNNNWKcoNWNNXXWWWWKkdolcccldkXWWN0o;;;,;OWKOo:;;;;;;;oXWWWWWWWWWWWWXKOkxxxxk0WMM    //
//    MMNXKXNXXNXKKKXNXXNNKKXWWNNNNNWNo''''oNWNNNNWKcoNWNOoxXWNWWWWWWNNWWWWWWNNWXkc,',kWWXKKKX0kkkkO00000000000000000000NNXNMM    //
//    MMNXKXNXXNXKKKKKXXXKKKXNWNWNNWWW0l::l0WWWWWNWKcoNWWX0KNWNWNNWWWWWWWWWNWWWNWWXkc;kWNNNNWWOlcccccccccccccccccccccldkkllKMM    //
//    MMMNXNNWWNXXXXXXXXNXXXNWWWWWWWWWWNXXNWWWWWWWWXdkNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXOKWWWWWWW0lccccccccccccccccccccdOkl,.:KMM    //
//    MMWNNXXNNX0xdkxdkk0XKOO0OO0OO0O0X0xkkdON0xk00kkO0Oxk00kkO0OkxkO0kkkkkKWWXNNXNNNNNNNNNNNW0lcccccccccccccccccldOkl,;:':KWM    //
//    MMWXKKKKKXKkoc:c::cokOxddddddxkkdlc:::dXOollodolodollodolldddllodolllOWNKKXKXKKXKKXKXKXNOlcccccccccccccccldkkl,;dKk,:KMM    //
//    MMWXKKKKKKKXKko:c:::cdOOxddxkkdcc::cc:xXkoddllddoloddllodolodddloOK00XWNXKXKKXKKXKXKKXXNXOkkkkkkkkkkkkkkkOkl,;dKWMk,:KMM    //
//    MMWXKKKKKKKKKXKko:c:c:cdOOkkdlc:cc::c:dXOodxxdllddoloddllodollld0XK000KXNKKXKKXKXKKXKXXNNKKKKKKKKKKKKKXNOl,;dKNXNMk,:KMM    //
//    MMWXKKKKKKKKKKKXKklc:cclx00klcccc:c::cONXKXKKKOdllddoloddlldddoo0X00000XNXKXXKXXX0KXXKXNX00000000000KKOl,;dKNXxdKMk,:KMM    //
//    MMWXKKKKKKKKKKKKKXKkoldkkxdkOko:cc::cxXX00000XNOddllddoloddlclddOXXKKKXNNXXKXXXk:;:dXXXWX000000000KKOl,;dKWKkocoKWk,:KMM    //
//    MMWXKKKKKKKKKKKKKKKXKK0xdddddkOkl:c:cONK00000KN0loddllddolodddlldkOOOKWNXKXKKNXo'''cKNXNX0000000KKOl,;dKNXklcccoKMk,:KMM    //
//    MMWXKXKKKKKKKKKKKKXXXXX0xddddddO0xlccxXXK000KXNOoodxkxodkkdodxkxodxkdOWNXKKXKXNXkxkKXXXNX00000KKOl,;dKNKxlccccclKMk,:KMM    //
//    MMXkx0KXKKKKKKKKXXXKKKKXX0xddddddkOxlcxNNXXXNWWXXXXXXXNXXNXXNKXNXXXXNXNNKXKXXKXXXNNXKKXNX000KKOl,;dKWWNOkkkkkkkOXWk,:KMM    //
//    MMNkodx0XXKKKKXXXKKKKKKKKXK0kddddddkOkONXKKKXNNXNNXNXXNXNNXNNXXNXNNXXXXXXXXXXXXXXNXXXXNWX0KKOl,':xO000000000000000o':KMM    //
//    MMNkddddx0XXXXXKKKKKKKKKKKKXK0kddddddkKXOkkxkxkxkkkkxkxkxkxk0kxkxk0KOxooololdooooooolooONNKxc::::::::::::::::::::::;oKMM    //
//    MMXkdddddx0KKXKKKKKKKKKKKKKKKXX0xddddoOXxododododdddoxdxodddOdododoxO0xlc:c:c:c::c:clkOOKKKXXXKXXXK0KKKXXXXXXXKKKKXXNWMM    //
//    MMNOxxxxO0xox0XXKKXKKKKKKKKKXKXXX0kxxx0Xxododododdx0KXXXK0xdOdodododox00xcc:c:c::c:k0xc::::lONNNXkkOkddkXNNWNK0000KXNWMM    //
//    MMWK0K0KX0O000KXKXXKKXKKXKKXKKKKKXK0KXNNxododododOXWNXXXNWX0Odododododdd00xcc:c::coKl,l0XKx;;OWXkkkdccld0NWX000XXK00KWMM    //
//    MMXxllllllodddolllllllllllllllllllld00KXxodododokNWX00000XWNXxododododddddO0kcc::cd0:,kWMMXl'xWXOolcldkkxKWX00KXNK00KWMM    //
//    MMXdcccldOK000KOdlcccccccccccccccoO0x;oXxodododoxNWN00000NWNXxododododdddoddO0kc:cc0k;;oxdc,lKNNklcdkkolkXWWX000000KNWMM    //
//    MMNKO0O0NKo:;:l0X0OO0OOOOOOOOO0000x:''oXxododododkKWNXXXNWKOOdododododdddododxO0kl:oxkdolodOXNXNNKKX0kOKNXXNNNXXXXXNNNMM    //
//    MMWXKKKNNd'''''oNNKKKKKKKKKKKXNXx:''''oXxododododddOOKKKOOddOdododododdddodododkO0kl;loxNNNNXNXNXXNNNNNXNXXXXNNNNNXNXXMM    //
//    MMNK000XW0c,,,cONX000000000KXKx:''''''oXkxxxkxkxxxxxxkxxxxxx0xxkxkxxxxxxxxkxkxkxxOK0xdldXXXNXNXNXXXXXXNXNXXXXXXNXNXXXXMM    //
//    MMNK0000KNX000XNK00000000KXKx:''''''''lXNXXX0kKX0OXNXXXKkOXXK00XXXXN0kOXKOKNXXNXOkKNK0KKXXXNXNXNXXXXNXNXNXXXXXXNXNXXXXMM    //
//    MMWK00000KKKXXK00000000KXXkc;,;;;;,;;,oNX0XXo;kXxo0NKKN0:c0KxodXN0XNx;oXOoONX0XXl;kXxo0XXXXNXNXNXXXXNXNXNXNXXNXNXNXNXXMM    //
//    MMWWWWWWWWWWWWWWWWWWWWWWMNKKKKKKKKKKKKXWWWWMNXNWNNWMWWMWXXWWNNNMWWWMWXNMWNWMWWWWNXWWNNWWWWWWWMWMWWWWWWMWMWWWWWWMWMWWWWMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CARRES is ERC721Creator {
    constructor() ERC721Creator("Carres by Kipz", "CARRES") {}
}