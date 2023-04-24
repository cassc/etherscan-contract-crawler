// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Psychedelic Swamp Squad Stories
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNXXK000OOOOOOkkkkkkkkOOOO00KKXXNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXXK0OOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOO0KKXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXK0OkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkO0KXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWWNX0OOkkkkkkkkkkkkkkkkkkkkkkkkxddxkkkkkkkkkkkkkkkkkkkkkkkkOO0XNWWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWNK0Okkkkkkkkkkkkkkkkkkkkkkkkkkkko;;lkkkkkkkkkkkkkkkkkkkkkkkkkkkkO0KNWWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWNK0Okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkc..ckkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkO0KNWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWNX0Okkkkkkkkkkkkkkkkkkxkkkkkkkkkkkkkkx:..;xkkkkkkkkkkkkkkxkkkkkkkkkkkkkkkkkkO0XNWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWNK0kkkkkkkkkkkkkkkkkkkkocdkkkkkkkkkkkkkd,  'dkkkkkkkkkkkkkdcokkkkkkkkkkkkkkkkkkkk0KNWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWNKOkkkkkkkkkkkkkkkkkkkkkkl':xkkkkkkkkkkkko.  .okkkkkkkkkkkkx:'lkkkkkkkkkkkkkkkkkkkkkkOKNWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWNKOkkkkkkkkkkkkkkkkkkkkkkkkd'.cxkkkkkkkkkkkc.  .ckkkkkkkkkkkxc.'okkkkkkkkkkkkkkkkkkkkkkkkOKNWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWWXOkkkkkkkkkkkkkxxkkkkkkkkkkkx; .lkkkkkkkkkkx:    ;xkkkkkkkkkko. ,dkkkkkkkkkkkxxkkkkkkkkkkkkk0XWMMMMMMMMMMMM    //
//    MMMMMMMMMMWN0kkkkkkkkkkkkkkko:okkkkkkkkkkk:. ,dkkkkkkkkkx,    ,dkkkkkkkkkd,  :xkkkkkkkkkko:lkkkkkkkkkkkkkkk0NWMMMMMMMMMM    //
//    MMMMMMMMMWXOkkkkkkkkkkkkkkkkd,'lxkkkkkkkkkl.  :xkkkkkkkko.    .okkkkkkkkx:. .ckkkkkkkkkxl',okkkkkkkkkkkkkkkkOXWMMMMMMMMM    //
//    MMMMMMMMNKOkkkkkkkkkkkkkkkkkx:..cxkkkkkkkko.  .ckkkkkkkkl.    .lkkkkkkkkl.  .okkkkkkkkxc..:xkkkkkkkkkkkkkkkkkOKNWMMMMMMM    //
//    MMMMMMWN0kkkkkkkkkkkkkkkkkkkko' .:xkkkkkkkd,   .okkkkkkx:      :xkkkkkko'   'dkkkkkkkx:. .okkkkkkkkkkkkkkkkkkkk0NWMMMMMM    //
//    MMMMMWX0kkkkkkkkkkxodkkkkkkkkx:   ;dkkkkkkx;    ,dkkkkkx,      ,dkkkkkd;    ,xkkkkkkd;.  ;xkkkkkkkkdoxkkkkkkkkkk0NWMMMMM    //
//    MMMMWXOkkkkkkkkkkkxc;lxkkkkkkko.   ,okkkkkxc.   .:xkkkkd'      'okkkkx:.    :xkkkkkd,   .lkkkkkkkxl;cxkkkkkkkkkkk0XWMMMM    //
//    MMMWN0kkkkkkkkkkkkkd;.;dkkkkkkx;    'okkkkkl.    .lkkkkl.      .lkkkkl.    .lkkkkko'    ;xkkkkkkd:.;dkkkkkkkkkkkkk0NWMMM    //
//    MMMN0kkkkkkkkkkkkkkko' .lxkkkkkl.    .lxkkko'     .::;,.        .,;:;.     .okkkxl.    .lkkkkkxl' 'okkkkkkkkkkkkkkk0NMMM    //
//    MMWKkkkkkxxxkkkkkkkkkl. .;dkkkkx,     .:ooo:.                              .:loo:.     ,dkkkkd;. .cxkkkkkkkkxxkkkkkkKWMM    //
//    MWXOkkkkkxl;lxkkkkkkkx:.  'lxkkkc.      ..     ...',;:cc,      ,cc:;,'....    ..      .ckkkxl'   :xkkkkkkkxl:lxkkkkkOXWM    //
//    WN0kkkkkkkx:.,lxkkkkkkd,   .;llc'       .',;clodxxkkkkkd,      ,dkkkkkxxdolc:,'.       'clo:.   'dkkkkkkxl,.;dkkkkkkk0NW    //
//    WKkkkkkkkkkd;..'lxkkkkkl.        ....  .lxkkkkkkkkkkkkkl.      .ckkkkkkkkkkkkkxl.  ....        .lkkkkkxl'..;dkkkkkkkkkKW    //
//    N0kkxxkkkkkkd,   'lddl;'    ..,:codd, .lkkkkkkkkkkkkkkx;        ;xkkkkkkkkkkkkkkl. 'odoc:,..    ';lddl'.  ,dkkkkkkxxkk0N    //
//    KOkxl::lxkkkkd,    ..   .';coxkkkkkc. ;xkkkkkkkkkkkkkkd'        .okkkkkkkkkkkkkkx; .cxkkkkxoc:'.   ..    ,dkkkkxo::lxkOK    //
//    0kkkxo;.';ldxx:.    .':ldxkkkkkkkkx; .ckkkkkkkkkkkkkkkl.        .lkkkkkkkkkkkkkkkc. ,xkkkkkkkkxdl:'.    .:xkxl;'';oxkkk0    //
//    Okkkkkxl'. .'.. .';ldxkkkkkkkkkkkkd, .lkkkkkkkkkkkkkkkc.        .ckkkkkkkkkkkkkkko. 'dkkkkkkkkkkkkxdl;'. .',...,lxkkkkk0    //
//    Okkkkkkkxc.   .;oxkkkkkkkkkkkkkkkkd, .lkkkkkkkkkkkkkkx:          :xkkkkkkkkkkkkkkl. 'dkkkkkkkkkkkkkkkkxo;.   'lxkkkkkkkO    //
//    Okkkkkkkkkd:.  .:okkkkkkkkkkkkkkkkd, .:xkkkkkkkkkkkkkx;          ;xkkkkkkkkkkkkkxc. ,xkkkkkkkkkkkkkkkxo:.  .:dkkkkkkkkkO    //
//    Okkkkkkkkkkxo'   .,lxkkkkkkkkkkkkkxc. 'dkkkkkkkkkkkkkx:.         :xkkkkkkkkkkkkkd, .ckkkkkkkkkkkkkkxl,.   'okkkkkkkkkkkO    //
//    Okkkkkkkkkkkkd'     .;lxkkkkkkkkkkkd, .:xkkkkkkkkkkkkkl.        .ckkkkkkkkkkkkkx:. ,dkkkkkkkkkkkxl;.     'okkkkkkkkkkkkO    //
//    Okkkkkkkkkkkkkl. .'.  ..;cdxkkkkkkkkl. .cxkkkkkkkkkkkkd'        'okkkkkkkkkkkkxc. .lkkkkkkkkxdc;..  .'. .lkkkkkkkkkkkkkO    //
//    Okkkkkkkkkkkkkd' .odc,.   .';coxkkkkxl. .:xkkkkkkkkkkkx:.       :xkkkkkkkkkkkx:. .cxkkkkxoc;'.   .'cdo. 'dkkkkkkkkkkkkkO    //
//    0kkkkkkkkkkkkko. 'dkkxdc,..   ..,:codxl.  ,oxkkkkkkkkkkd,      'dkkkkkkkkkkxo,  .lxdoc:,..   ..,cdxkkd, .okkkkkkkkkkkkk0    //
//    Kkkkkkkkkkkkkd,..lxkdlccodoc,..     ..''   .,oxkkkkkkkkko.    .lkkkkkkkkkxo;.   .,..     ..,:odoccldkxl..,dkkkkkkkkkkkkK    //
//    XOkkkkkkkkkkkc..cxkx;.  .,okkxoc:,..         ..,;;::cccll;.  .;lllcc:::;,..         ..,:coxkko,.  .;dkxc..ckkkkkkkkkkkOX    //
//    WKkkkkkkkkkkkc..ckkd' ,c'.'okkkkkkxdoc:,'..                                  ..',:cldxkkkkkkd,.'c, 'dkkl..:kkkkkkkkkkkKW    //
//    WXOkkkkkkkkkkd,..co:..:kl..ckkkxoc::coxkxxdolc:;,,'..................',;;:clodxxkkdl:;:oxkkkl..ck:..:oc..'okkkkkkkkkkOXM    //
//    MWKkkkkkkkkkkkd;...  'okc..lkkxl......:dkkkkkkkkkkxxxxdddoooooodddxxxxkkkkkkkkkkxc.... .cxkkl..cxl'  ...;dkkkkkkkkkkkKNM    //
//    MWN0kkkkkkkkkkkxdlccldkx;.'dkkx; .od:..:xkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkx:..;ol. ;xkkx,.;xkdlccldxkkkkkkkkkkk0NWM    //
//    MMWXOkkkkkkkkkkkkkkkkkkd, ;xkkkc..okx; .okkkkkdc;;:oxkkkkkkkkkkkkkkxoc;;cdkkkkko. ;xko..:xkkx:.'dkkkkkkkkkkkkkkkkkkOXWMM    //
//    MMMWKOkkkkkkkkkkkkkkkkkd, 'okkkl..ckk:..lkkkkl' ....;dkkkkkkkkkkkkd;.... .lkkkkl..:xkc..ckkkd' ,dkkkkkkkkkkkkkkkkkOKWMMM    //
//    MMMMWKOkkkkkkkkkkkkkkkkxc. 'ldo;..ckkc..ckkkx; .cdc..;xkkkkkkkkkkx;..:dc..:xkkkc..:xkl. ,odl, .:xkkkkkkkkkkkkkkkkOKWMMMM    //
//    MMMMMWKOkkkkkkkkkkkkkkkkxc..... .:dkkl..ckkkx:..okx; .lkkkkkkkkkko. ;xko..:xkkkc..:xkx:.......:dkkkkkkkkkkkkkkkkOKWMMMMM    //
//    MMMMMMWKOkkkkkkkkkkkkkkkkkdlc:cloxkkkl..:xkkkl..lkkc..lkkkkkkkkkkl..:xkl..ckkkkc..:xkkxdlc::ldkkkkkkkkkkkkkkkkkOKWMMMMMM    //
//    MMMMMMMWXOkkkkkkkkkkkkkkkkkkkkkkkkkkkl..:xkkko..lkx; .okkkkkkkkkko. ;xkl..lkkkx:..ckkkkkkkkkkkkkkkkkkkkkkkkkkkOXWMMMMMMM    //
//    MMMMMMMMWN0kkkkkkkkkkkkkkkkkkkkkkkkkko' .cddo;.'okl..:xkkkkkkkkkkx:..lko' 'oddc. 'okkkkkkkkkkkkkkkkkkkkkkkkkk0NWMMMMMMMM    //
//    MMMMMMMMMWNKOkkkkkkkkkkkkkkkkkkkkkkkkko,...'..,oko'.,dkkkkkkkkkkkkd;.'oxo,......,okkkkkkkkkkkkkkkkkkkkkkkkkOKNWMMMMMMMMM    //
//    MMMMMMMMMMMWX0kkkkkkkkkkkkkkkkkkkkkkkkkxdlllldxkx:..lkkkkkkkkkkkkkko. ;xkxdollldxkkkkkkkkkkkkkkkkkkkkkkkkk0XWMMMMMMMMMMM    //
//    MMMMMMMMMMMMWNKOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkd, ,dkkkkkkkkkkkkkkx; 'dkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOXWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWNKOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkko. :kkkkkkkkkkkkkkkx; .okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOKNWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWNKOkkkkkkkkkkkkkkkkkkkkkkkkkkkkd' ;xkkkkkkkkkkkkkkx, 'okkkkkkkkkkkkkkkkkkkkkkkkkkkkOKNWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWNX0Okkkkkkkkkkkkkkkkkkkkkkkkkx:..cxkkkkkkkkkkkkx:. ;xkkkkkkkkkkkkkkkkkkkkkkkkkO0XNWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWXKOkkkkkkkkkkkkkkkkkkkkkkkkd;..'cdxkkkkkkxdc'..;dkkkkkkkkkkkkkkkkkkkkkkkkOKXWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWNX0Okkkkkkkkkkkkkkkkkkkkkkxl,...';;::;;'...,lxkkkkkkkkkkkkkkkkkkkkkkO0XNWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0Okkkkkkkkkkkkkkkkkkkkxoc;'......';coxkkkkkkkkkkkkkkkkkkkkO0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNX0OOkkkkkkkkkkkkkkkkkkkkkxxdddxxkkkkkkkkkkkkkkkkkkkkOOKXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXK0OOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOO0KXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXXK00OOOkkkkkkkkkkkkkkkkkkkkkkOOO00KXXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM_WELCOME_TO_THE_SQUAD_MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM_THESE_ARE_THE_STORIES_OF_THE_PSYCHEDELIC_SWAMP_SQUAD_MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM_ARTWORK_BY_MOBSOLETE_MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PSS23 is ERC1155Creator {
    constructor() ERC1155Creator("Psychedelic Swamp Squad Stories", "PSS23") {}
}