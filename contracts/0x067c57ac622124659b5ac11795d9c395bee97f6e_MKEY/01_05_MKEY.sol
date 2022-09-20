// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: memories.key
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    0WMMMMMMWKd,..................................':o:'..''....,ldxoloxKMMMWKx:''''.'''.................    //
//    MMMWMMMMMWKl,''..........................,:cldxKN0Oxxko::;'',;ok0NMMMMMWWXo',:codx:.................    //
//    MMMWWMMMMMWNOxkdc,.....................,lxO0000KKXXNNNXOd:',;:x0XWMMMMMWWW0ddOOOo;'.................    //
//    NWMMWWWWMMMMMMWWNkl;''............''.,cdkOOOO000Okxdc;,...;kXXXXNMMMMMWWWWKOkkkko,...';:cccc;''''...    //
//    0KXXNNNNNNNNNNWWWMWK0kl'.........',,;dkkkkOOOOOOo..       .lOXNXNWWNXNWMMMNKxc::;,',cxKNNWWW0xl:,'..    //
//    ;cccclllldddolloxkkxdl;'.........';cdkOkkkkkOOko'         .,d0XKKKK00KXNWWWKl'.'';lkXMMMMMMMMMWX0o;,    //
//    ''..''''.'''''''''''................,;lxkxxxkkdl:'....    .:k00000000OO00KKd:cc:lOWMMMMMMMMMMMMMMNKK    //
//    ..............''..'.................'',cc:lxkkxkkxl;.      .cOKK00OOOOOOkddxkkkkO0XWMWNWMMMMMMMMMMMM    //
//    ..........'...''.''...'''.'.'....'''''''''ckOxxxxkkx;       'okkO0OOOkkkxdolc:::::oKWWWWMWWMMMMMMMMM    //
//    '..'''''.''.....''''..''.''.''''''''''';:::cldxdollc. ...      .'oOOOOkdc,,'','',;:dKWMMWWNWMMMMMMMM    //
//    '''''''''''''''''''''''''''''';:,''',:dKXXKKkxxl,'.....        .,xKOkdc;;,,,;:,,coll0WMWWMMMMMMMMMMM    //
//    ''''''''''''''''''''''''''''ckkdlodk0XWMMMMMMMWO;.....        .ck0Oxl;''''';llc:oxxxkOKXWMMMMMMMMMMM    //
//    ''''''''''''''''''''''''''',:ddoOWMMMMMMMMMMMWXd....         .lkdlc,''''',;::;,,;:;;,,;:o0XNMMMMMMMM    //
//    '''''''''';,'''''''''''''',:oookXMMMMWWMMMMMWXo..            .od;''''',''''',,,,,,'',::,,:dKWMMMMMMM    //
//    '''''''''',,''''''''''',ldxXWWWWMMMMMWWMWMWXOo'               .;,''''',''''''',:lc:;lxdld0NMMMMMMMMM    //
//    ''''''''''''''''''''''',cdxOKXXX0O0XWMMMWXo,.                  .',''''''''''',,;lxdoddx0WMMMMMMMMMMM    //
//    ',,,',,''''''''''''''''''',,::c:;;;o0XK0kc..                    .',,''''''''''';odolccdKWMMMMMMMMMMM    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,;,;;,;;;;cdkd:,...                      .,,,,,',',,,,;::::ld0NMMMMMMMMMMMMM    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,;ccldoddddkxc....                       .',,,,,,,,,,;cl:,,;okKWMMMMMMMMMMMMM    //
//    ,,,,,,,,,,,,,,,;,,,,,,,,;:oddooll:;'.                          ..',,,,,,,,,:c:;,,,,ldkKNMMMMMMMMMMMM    //
//    ,,,,,,,,,,,,,,;;,,,,,,,;cllccloc'...     ..         .....        .',,,,,,,,,,,,,,,,,,,cxKWMMMMMMMMMM    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,;;;:;'.     .''....    .,.',.   ....  .,,,,,,,,,,,,,,,,,,,,,:oONWWNNNWMM    //
//    ;;;;,,,;;;;;;;:codo:;,,,,;;;;;;,..       .'',:;.  .';,'.   .lk0o. .';;,,,,,,,,,,,,,,,,,,,,:xOkold0WW    //
//    ;;;;;;;;;;;;;;:lxOOd;;;;;;;;;;,.           ..,:.   .,'.   .lO0XXo. .';;;;;;;,,,,,,,,,,,,,,;;;;;;:dKX    //
//    ;;;;;;;;;;;;;;cxOkOxolc;;;;;;;.      ..    ..;c'    .'..  ,xOO0KKl. ..;;;;;;;;;;;;;;;;;,,;;;;;;;;:cl    //
//    ;::::::::::::::okkkkOOkdc:::::;.    ..   .,;:ll'   .:lc;. ,kK00O00c.  .,;;;;;;;;;;;;;;;:;;;;;;;;;;;;    //
//    :::ldkO0OkOOxoccoxkkkkOOkxxxxkkxl,.     .lOkkkd,   ':,,'. cXWWNKOOOc.  .;:;;;;;;;;;;;;::;;;;;;;;;;;;    //
//    odxKWMMMMMMMWNKOdldkkkkOkkkOkkkkOkl'   .:kkkdoc.    .....'xWMMWX0OOOc.  .;:;;;;;;;;;;;;;;;;;;;;;::;;    //
//    NWWMMMMMMMMMMMMMNOllllodxoooxkxxkkkc.  .okxdxdl.   .,l:;lkXWMWWMWX0OOc.  .;:::::::::::::::;:::::::::    //
//    NWWMMMMMMMMMMMMMMKoccccccccclolclxko,,,cKNXKXXKxoookK0xkOKNMMWWNNNNX0k:.  .;::::::::::::::::::::::::    //
//    dxkKWWWWWMMMMMMMMWOoccccccccccccclooodoxKXWWWWWWWWWWNXXXNNWWNKOOOKNNX0Oc.  .:c::::::::::::::::::::::    //
//    cccoxkkkKWMMWNNNWN0dlcccccccccccccccodddkOKXKOxdddddxOKKK00OxlcclokKXKK0c.  ':ccccccc:::cccccccccccc    //
//    ccccccccokOKKOddxxollcclcclcllllcccccoxxxxdoll:.....';oxoc:;,'''',;lkO00Oc. .'cccllccccccclodk00Odol    //
//    ccccccclllllllllllllllllllllllllllllclllllllll;..'''. ,ol;;;'..''',:oxOO0k:. .,lokOkxolllokKNWMMWN0x    //
//    llllllllllllllllllllllllllllllllllllllllllllll'       .:oooo:,;cc::cdxkOOOkl. 'kXWWWWX0O0KNWWMMMMMWK    //
//    lllllloooolooooloooooooooooooooooooooooooooool.    .'. 'odoooccoooxOkxdxxkO0Oc:0MMMMMMMMMMMWNWWMWWWK    //
//    ooooodxxddoooooooooooooooooooooooooooooooooooc.  .'cc. 'oddddddddxxxddddx0NWWNKXMMWWMMMMMMMMWWMMWWWN    //
//    dddx0XNNXOxddoddddddddddddddddddddddddddddddd;. .;ool. .cddxkO00KXK0KKKKXWMMMMMMMWNNWMWWWWWWWWWWWMMM    //
//    OOKXNWWWWN0xddddddddddddddddddddddddddddddddo'  'oxdo' .cxxONWWWWWMMMMMMMMMMMWWMMWWWNNXNNNWWWWWWMMMM    //
//    KOOOOOO0OOOxxxxxxxxxxxxxxddddxxxxdxxxxxxxxxx:. .lxdxd;.cxxxOKXXXXNNWMWWWWWMWWWNNNWWWWNNNWWMMMMMMMMMM    //
//    Xkxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkxxxxxxxxxxxl.  ;xxxxxlcdxxxxxkkk0KKKXXXKKXNNNXK0O00KKKK0KXNNWWWWWWNN    //
//    XOkxxxxxxxxxxxxxxxxxxxxxkkkkkOKNX0kkkkkkxkd,  .lkxkkkxxxkxkxxkkkkkkkkOkkkkkkOkkxxxxxkkkkkkkO00000OOk    //
//    WXkkkkkkkkkkkkkkkkkkkkkk0XXXXXXNNNKOkkkkkx;  .;xkkkkkk0KK00kkkkkkkkkkkkkkkkkkkkkkkxkxxxkkkkkkkkkkkxx    //
//    WKOkkkkkkkkkkkkkkkkkkkkkO000K00OO00Okkkkx;..:okkkkkk0XWWMWWKOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    MWNX0O0O0KXNXK0OOkOOOkkkkOkOOkkOkkkOkkkkc,cxkkkkkOO0NMMMMMWNXNNXK0OkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    MMMMWNWNWWMMMMWXK0OOOOOOOOOOOOOOOOOOOOOxoxOkOOOOOOO0NMMMMMMMMMMMWN0OOOOOkkOOOOOOOkkOOOOOOOkkkkkkkkkk    //
//    MMMMMMMMMMMMMMMMWWX0OOOOOOOOOOOOOOOOOOOOOOOOOOOOO0KXWMMMMMMMMMMMMMNK0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    MMMMMMMMMMMWX0KNWMWXOO0K0kdxkkkOkkOOkkkxdccloxxO0xdx0XWWNNWMMMMWWWWWXkxkdc;cddcccoxkxl:coxOOOOOOOOOO    //
//    MMMMMMWKdlod:..,cxkooolc;.....''..'''....   ..';'.  .';;,;dO0kl;;:ckk,...   ..   .....  .;dOOOOxdxOO    //
//    MMMWWMK:.        .. ..                                     ...     ,c;.                  ..lOOo'.,xO    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MKEY is ERC721Creator {
    constructor() ERC721Creator("memories.key", "MKEY") {}
}