// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Patriots Coin
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMXoxWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKkO0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWKo;dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0kkkkkkk0NMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWWKx:::xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0dx0O0KX0kdxXMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMWMWXkc;;::oKMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMWNXKKOdldOxdk0KkoocxNMMMMMMMMMMMMMMMMMMWWMMMMM    //
//    MMMMMMMMMMWKxc;;,;;::lkKNMMMMMMNK0KXNNWWWWWWWNNNNXXXXK0kdolc,:kdclxOOl.'loxO0KXXNNWWMMMWWWNNXXKKWMMM    //
//    MMMMMMMMMMWOc;'',;::clccokNWWMXOkdodxk0KKKKKK00Okxxdolc:;,,,;dOx:coxk;  'ol:llldxkkO00000OkxdokOONMM    //
//    MMMMMMMMW0xoc;''::;colccccxNWXOkl;,;;:cclllllcc:;;,,;,,;;;,,lxOkc;cll,   :c,,,;;::clccccc:;;;;:xOONM    //
//    MMMMMMW0l:;;;,,::::cllc:cloKNOko;,cl;,;,,,,:oc,;,,;;,;ol,,,cdxOko;;;:;.. ,c;;;,;::xd:;;;;:cdkl:ckO0W    //
//    MMMMMMO:,;'''';;;;clc:::codK0kd:lxKXko:;;cd0N0dc;,,:oOXXxclxxdddc;,',,'. 'ooc;,:oONNkc;;:looxkd:cO0K    //
//    MMMMMWkoo:,,',;:;;c:,;::loxX0xl,:kXX0l;;,;oKKKd;,;,,cOKOolxk0Oo:;,,,;;,'.,oc;,;,:kkko:lxx;. ,:;;;d0K    //
//    MMMMMWN0oc:,,::;;;,;ll::lcOKkx:,;cc:l:,;;;cc:cc;,,;,::;cdddOOo::;,;,;;,..;;;;;;,;:,,:cloc. :kc,,,cO0    //
//    MMMMMXxc:;,';;,;;,:xOkdl:lXKko;,,,,,,,;ll,,;;,,;cc;;cldOOocol;;,,;;:do;..',;;odc,,ckkc;,..:Odc,,,;kK    //
//    MMMMXo;;''''',;;,,oKKxllcokddl;,,,,,:okXKxl:,,:clddodddxxocc:;;;::okK0x, .;lkXKd:cxkdc,..lklc:,,,,dK    //
//    WMMM0dl;,;,',;;;,,lxkxxxxxddoc,,,,;;;l0XKx:;:codkkOxollodddddooxxdxOOOd..;,,okdxxdll:'.,oo,',,;,;,d0    //
//    MMWMNOoc:,,,,;;;,,;;cx0KK0kdll:::;;;,cooooldxdlokxddxxkkdokkc;cxxoOkxkddxkdolcdkdlc,..lo;.',;;,;;,o0    //
//    MMNOoc:;'''',,,',l:,:oxk0K0xoooddoollodxxookOklldkOOxdxOdcdkooxOOOKOkxxKklx0Okxdol;.;o:';ccc:;;;;;d0    //
//    Xxc;:;,,'.'''....ld:;:ldkkook00OkxolxOO00dlxoloxxddOd:ldxxxkO0KKXNNNKKKKkx0xclxOo;,;;,'lKNXNOlcccckK    //
//    dcooloc,.',,......:doc:colldkO0000dokOOOkocclk0d:cdkkxkxodkxd0XNNNKkkOxxO0kdclxl',:,,ccoXWN0xlcc:cOK    //
//    WWWWN0ocld0Od:.....cxolc:clloddxxxoloolc:;;o000OddxkkxxxoxOxd0XXXX0dkKkdkkkkkkkdx0XOlc:oOOxdxOOkdlxK    //
//    MMMMWNNWMMW0o;,,,ckNN0xol:;cloooxxxdoc,,';d00OkkOOOOkkkkdxOxdk0000xoON0xOOkxddkOO0NN0lcodoodkOOxoolO    //
//    MMMMMMMMWOl,';coONMMMMNOxolc::lddddxxd:',o000kddx00000Oxdddoodx0K0kO0K0O0KKOdokkdkXXXOxkkdcokOd,..:O    //
//    MMMMMMMMXxoxkKNMMMMMMMMMN0xdo:codxkkkkc.cOOxkkdolodOK0koddooddxkOKNXOxdooodkOOKOdkK00Kkll:;clc'.',:0    //
//    MMMMMMMMMMMMMWMMMMMMMMMMMMXxdc:oodxOK0c,x0xdxkkkxdoxOOxoxkkk0KXKx0WWK0OkOOxloOX0dxK0k0Ol:c:;,.'c:;dN    //
//    MMMMMMMMMMMMMMWMMMMMMMMMMMWOdl;:cldxOOl:kOdxkkOOxdoxkkdooox0XNW0o0NX0xx0NWN0od00dx00dxOxxOl',odl:dXM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWMMXxlc;lxO0KXxcxxoxkO00kdodxkxxxdONNWWOkXXOxx0NWNNXkoodox00xxkl:::oocckKNMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMOc::ooodkOxloxdk0KXXOoodk0OkxxKWWMNOxxdokKNWNNXX0kkkkkko;'..,cddlck0XMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMKd:::cloxxl:okokKXNNOook0K0dlo0WWWNOddOXNWNNNXXKkldxkkkdccllxOKNKO0KWMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNkc;,codOKKkokddXNNXOdokXNKxooxXWNNKxxKWNNNXXX0xooxxkkkkdxkxXWWWX0KWMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMXdcccclodkklxKKXXK0kdd0WWXkdddxOKXKOxk0KKKK0kdodxkxkkk0kkddXWWNKKNMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOdlc:cokOllKNXOxk0K0XWWX0OOOkookO0KKK0000kxdddoxkOOkkkxcoXWNKKWMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOxl:cxxl;l0XOoodxxxxddddkX0xxxodxkOO0kdddoooollxxxkdl:dXN0KWMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWW0oc;cdxxddxkkxxdddddddoON0xXNKOOxoxkdoxxxxxdddddxdcccd00XWMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKdc:ldxxxkdoO0OO0OOO0OddkdxKXXXK0dlolokkxxkOOkxkdcccok0XWMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkl::c;...,;d0O0000KKNK0O0KXXKKK0OkxxdxOOkkkxxOKkcldOKNMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo:,. .;,.;dO0OOKXNXxdkO0kxxxOdxxcc:lkkxxxOKNWOdk0XWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0d;..,ooc;:lolldkOkkOKKxxxdOxdOxddooolcOWWWXOOKWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0d:,',:;;;;::;;;:clllcclodxOO0kl:ccl0WX0OKNWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0xl:::::;;;;,,,'..';:lONWWKoccclk0OKNWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXKkoc;:xKXXkccc:l0WWW0lclodOKNMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWXKOxd0WWWkcccclKWWW0ooxOXWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKKXNNkccccl0N0OOOKNMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKKkdolook00KNWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNK0kkkOKWMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PTC is ERC721Creator {
    constructor() ERC721Creator("Patriots Coin", "PTC") {}
}