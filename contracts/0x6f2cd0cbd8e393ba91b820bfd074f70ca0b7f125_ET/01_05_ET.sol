// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ether Trophies
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMXOxxxxxxxkxxxxxxxxxxxxxxkxxxkxx0WMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMO:::;;;;;::::cccccccccc:::::;;,::oXMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMM0c;clclllllooooooooooooollollcl::dXWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWNOddd:.:olllloooooddddddddddddddoox:'lodx0WMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMXkl;'.'..cdllloddddxxxxxxxxxxxxxxxddkc....,cd0WMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMOc:;lxxx:.cdolloddddxxxxxxxxxxxxxxxddkc'odxdc::dNMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMx';'dMMWk,:dolloddddxxxxxxxxxxxxxxxddkccXWMNc,,;KMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMx,;,dWMMNx,cdollodddxxkxxxxxxxxxxxddkccKWWWXc;;:KMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMXd,;:kMMMO,:dolloddddxxxxxxxxxxxxxddk;cNMWXl;;:0WMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMO:;,lXWWXx;cdolloddddxxxxxxxxxxxddxcc0WMNk;;;oNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMW0:;;lXWMK:;oollloddddxxxxxxxxxxdxd;dMMNk;;;oNMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWKx:,ckXWKc;oollloddddxxxxxxxxdxd:oNWKo;,ckNMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMKd:,cxXKdcclccloddddxxxxxxxdookXKd:,ckXMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWKd:,:lx:.:ll:codddddxddxx:'odl;,lkNMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWKd:,'...,clllclodddddl;'.',,cONMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xllccccclloooddollclldOKNMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0;,clodl;lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:.:codc'dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc'ldxko'dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk;;llodl,:0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo,;:clll:;kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:.:loo:'dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK;.:cldc.lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    M0ddddddddONMMMMMMMMMMMMMMMMMMMMMWWXxc,'',;;;,;l0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    Wl........':kNMMMMMMMMMMMMMMMMMMXdl:;:lllllooooc:lokNMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    Wl.,,',',''..dOOO0OOO0NMMMMWWKdc,.',',,,,,;;;;;;;,'';lkXMMMMMMMMMMMMMMMMMMMMMMMM    //
//    Wl.,,,,,,,,'..,::clllooookKXK;.,,,',,;;::::::::::::;;,.dMMMMMMMMMMMMMMMMMMMMMMMM    //
//    Wl.,,,,,,,,,..cOO0KXXXOkxdool..,'''',,,;:::::::::::;;,.oMMMMMMMMMMMMMMMWWWWWMMMM    //
//    Wl.;,,,,,,,,..cO0KXXXXXXXXX0kdc;,'.....''''''''';::;;,.lWMMMMWMMMMNOkkkdooooxXMM    //
//    Wl.,,,,,,,,,..cO0KXXXXXXXXXXXXXKKOdooooooooooool:;,,;,.oWN0OOOxoooooolok0KKOdckW    //
//    Wl.,,,,,,,,,..cO0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0c..,'.;oollloxOOO0KXXXXXXXKO,lW    //
//    Wl.,,'''''''..cO0KXXXXXXXXXXXXXXXXXXXXXXKXXXXXXKKc.,cdkkkOKXXXXXXXXXXKXXKKK0x,oW    //
//    Wl.,''''''''..cO0KXXXXXXXXXXXXXXXKKKKKKKKK000K00x;:OXKXXXXXXXXXXKKKKK0000kollxXM    //
//    Wl.,'.........cO0KKXXXXXXXXXXXXXXOlccccccccccccccdKXXXXXXXXKKKK0K00OxooolodkXWMM    //
//    Wl.,'.........cO00KKXXXXXXXXXXXXXK0OOOOOOOOOOOO0KXXXXXKKKKK000kxdlcloooOXNWMMMMM    //
//    Wl.,'.........:xkO00KKXXXXXXXXXXXXXXXXXXXXXXXXXKXKKKK000OOxlcclox00KNMMMMMMMMMMM    //
//    Wl.,'...'....,clccoO00KKKXXXXXXXXXXXXXXXXXXXKKKK000OkdlclooxkOXMMMMMMMMMMMMMMMMM    //
//    Wl.;,,,,,,'.;0WW0xollok00KKKXXXXXXXXKKKKKKK0000kdolclodx0WWMMMMMMMMMMMMMMMMMMMMM    //
//    Wo.',,,,,,:dKWMMMMWNKxlcok000KKKKKKK000OkxxdllclokXXNWMMMMWMMMMMMMMMMMMMMMMMMMMM    //
//    MN00000000XWMMMMMMMMMWX0xlcoxkkkkkkxocclooldO00NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMXOxolllllloxkOXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract ET is ERC721Creator {
    constructor() ERC721Creator("Ether Trophies", "ET") {}
}