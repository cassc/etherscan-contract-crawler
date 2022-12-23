// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: To Be Found
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                //
//                                                                                                                //
//    MWWWWMMWMMMWWNXKKKOxl:clllccc:::::::;;,;;;;;;;:::::::::::cc;'...':ldkKWMMMMMMMMMMMMMMMMMMMWWWMMMMMMM        //
//    MWWWWMMMMMWNXKKKkoc:::::ccccclcc:;;;;;;;:;;;;;clc:;;:;;;;:cc:,....':odOXWMMMMMMMMMMMMMMMMMWWWMMMMMMM        //
//    MMMMMMMWWNNXKK0d:::::;:ccclccllc:;;;;;;;;;;;;;:ll:::;;;;;;;;::;,....':lxXMMMMMMMMMMMMWWMMMWWWMMMMMMM        //
//    MMMMWWWNNXXK0x:,;:::;::::ccccllc:;;;;;;;;;;;;:looccccc:::;;;;:::,......,oKWMMMMMMMMMMMMMMWWWWMMMMMMM        //
//    MMMMMWWNNNXOo,,cccc;;;::::c::::cc:;;;;;;;;;;;:codollllccc:;,;;;:c:,'....',oXNWMMMMMMMMMMMMMWWWMMMMMMW       //
//    MMMMWNNXNNk:,cccccc;;:::::::::::c:;;;;;;:;;;;;;:cc::::;;;;;;;;;;;::,.....':kKXWWMMMMMMMMMMMWWWMMMMMMM       //
//    MMMWNNXNNk;';:cccccc::::::::::::cc::::;;::;,''',;;,,,,'',;;;;;;;;;;;'.   .,dKXNWWWWWMMMWWMMWWWMMMMMMM       //
//    MMMMWXXNO;',;cccccc::::::ccc:cc:::::;;;;;'.  ..,;,,,,,,,;,,;;;;;,,;;,.  .'c0XXNNWWMMMMMMWWWWMMMMMMMM        //
//    MWWWNKXXc.,,;ccccccc:c:ccccc:c:::coddo:;;.   ,odo:;::;;;;,;;;;;;,,,,,.  ..:ONNWMMMMMMMMMMMWWWMMMMMMM        //
//    MWWWXKNk,';,;clllcccccccccccccccldOKKOl;;,..:kKKx:;;,,;;;cc:;;;;,,,,,,.  .;kNNWMMMMMMMMMMWWWMMMMMMMW        //
//    MWWNXXXo';cll,:llllcclccccool:::ccloxxdl:;;,,';xK0o;,,;lxxOX0o:;;;;,,,,;'. .,dXNWMMMMMMMMMMWWWMMMMMMMW      //
//    MWWNKXKc,:;;:lllllclcccc:;.       ':::'.... ,kKKxc::lxkkKNXd::;;;;,,;;,...'oKNWMMMMMMMMMMWWWMMMMMMMN        //
//    MWWNXN0c;:cll;:cllolclccc:'         ........',cxkxo:::cllcloo:;;;;;;,,;,','..lKNNMMMMMMMMMMMWWMMMMMMMN      //
//    MWWNXNkccc::::ldxxlcc:,.             .,::codoc:;;,,,,;;;;;;;;;;;;;,,,,,,..'oKKNMMMMMMMMMMMMWWMMMMMMN        //
//    MWWNXXd;ccc:ldddol;'..               ..,,;:lc,...',,;::;;;;;;,,,,,,,,','..,xXKNMMMMMMMMMMMWWWMMMMMWN        //
//    MWWNX0c,:::cxK0c....                   ...','..,::ccccc:;:::;;,,',,,,''...:0NKNMMMMMMMMMMMMWWMMMMMWN        //
//    MWWWX0c';:::looc;::.                     ....,:cccccllc:cdo:'....',,,'...,dKNXNWMMMMMMMMMMMWMMMMMMWN        //
//    MWMWNXx,'::;;;:cll;.                        ...',;;;,,''dNNk'.  .',,....'o0KWWNMMMMMMMMMMMMMMMMMWMMN        //
//    MWMWNXKo',:;;:c;;'.                                    .l0Kxc;,,,;;'. .'l0KXMMMMMMMMMMMMMMMMMMMMWMMX        //
//    WWMMWNXOc';:,'..                                 ....',;:ccc::;;;;'...'cOXKNMMMMMMMMMMMMMMMMMMMMWWNO        //
//    WWMMWNNNk:',,'....    ..'.           ..''        .';;:cclllclxkxl:;;,. .',:kXNNWMMMMMMMMMMMMMMMMMMWWNNX0    //
//    WWMMWNNWXkc,,:;;:;.    ';;.       .';;.        .:llccllllcd0K0d:;'. .,;:kNWMMMMMMMMMMMMWMMWWWWNXKKXNWW      //
//    WMMMMNXNNXKkdoc::;.                           .,,'',,,'';dkxl,. .';:l0WMMMMMMMMMMMMWWWWNNNNNNNXXNWWW        //
//    WMMMMMWWMWNNX0ko:,.                                 ...';cl:'..';:cxXMMMMMMMMWWWWNNNNNWWWWWWWWNNNWNW        //
//    MMMWWMMMMMMWNNNXOl.                           ...,,;::ccc;',c::clxKWMMWWWWWWWWWWWWWMMWWNNNNNWWWWWWWM        //
//    WMMMMMMMMMMMWWWWNKd'.                     ..''::ccllll:;;:o0KkdkKNNNNNWWWWWWMMWWWWWWWWWWWWWMMMMMMWWM        //
//    WMMMWWWMMMMMMMMMMWN0xc.                   .,..;loollc:lx0KKKKXXNWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMM        //
//    MMMMMMMMMMMMMMMMMMMMWXx'                 ..  ..;cloodk0KXXNNWWWWWWWWWWWWWWWWWMMMWWWMMMMMMMMMMMMMWWWM        //
//    MMMMMMMMMMMMMMMMMMWWWMNx'.             ...   .:dk0KKKKXNNNNNXOdodk000000OOkk0NWWWNKKOkkOOOOO00000OOO        //
//    MMMMMMMMMMMMMMMMMMWNNXKK0d:..         ....   .lOKXXXXXK0kxkOxl,..........','':llc:;;,...''',;:cldddo        //
//    MMMMMMMMMMMMMWWX0OOkkkOKNNKkd:..   ..'''......'oKNNNKOkxddodd:;'.  ....':loc...................';ldk        //
//    MMMMMMMWWXKOOkkkO0KXNWWWWWNNNKxl;;cdo:,'.....  .oKK0d:::lxxkx:;'...cdxO00Oxc..;::....,,.....',;loxO0        //
//    MWNK0OkkkkOO0XNWWWWNNNNNNNNXNNNKkdooooc;,...    .,;,'..'',:ol;,;,.:0NNXXNXKd;;;,'. .'oxolodkO0KK0KK0        //
//    OOkOO0XNWWWNNNNNNNWWWWMWNKxdkOOOkdolclol:'....  ..''..;:,,;;;,,;,.c0K0000KKKKKOd:';okO00KK0000kxdool        //
//    XWWWWNNNNNWNWWWMMMMWK0kdl;;coolxOkxlccloc;....  .',::,:llc:;;'.,;;lkKXXXXXKKKXKKOxk00kdolcc:;;,'....        //
//    NNNNNWWWMMMMMMMWNXOd:,'..',;ll;l000Oxoll:;,''...''.:xOOxo:'',;,'.',;:ddlldxxoc,'..';:;..........            //
//    WWWWWWWWNWMMMWN0dc,'....:odO0d,dNNNNXOdlolc;'',coc;lkklccc;,;,'..','','.',,;;'.....;,.........              //
//    NNNNNNNNNWNXOdl:,,'';clkKXKX0:,xXXKXXXOxdddol:;ldkkdl:;,;::,....'co:'...,,'.''.';;;,',;;;.......';cl        //
//    XWNNNNXOxdoc;,',:lxOXXKXXK00o':x0KK000Oxolloooc:cdkOx:,'.......',,'.  .........;:;,..,,,;;;lxdx000KX        //
//    XNX0xoc:;,;ccccx0XXKOOOkxddo;'lddxkxlclllllol::;,;coxl:,...'',;;,..........'.......'''...':xOkkKXXXN        //
//    Odl::cloxk0XKOxdol:::ldxdxOo,'ldddlc;:llllloc;;:,'';cdd:..;llllll:'.';:;,'.....','.........':odkKXNN        //
//    ,:lox0KXNX0Od:'.':ldkO0Odddl,':odxooooolcc:;,;;;::::coxd:'cxkdol:;:odxolcc:.. .,,.  ........'colokKN        //
//    dk000KK0Od:,';cdxxxdxkkdlcc;.....,:okkkxxdl;;;;;:loodddxl:oxdoll:cxOOOkdodo;. ..          ..':c:::cd        //
//    xO0OxkOOOdcclodolc:,,,,,,;:lolllllxKXKKKKXXkc'',,;cldxxl:lddloxddkOOOkkxxko'              ...:;'',;;        //
//    okxl:lddoc;,',,,''',:lxOKXNWWWWWMMMMWWWKxx00xlcc:;;:okkxoloodOOkOOOOOkkkko,.... ...         .,.....'        //
//    kd;. .....  ..,:lx0XWMMMMMMMWNNNWWMWNNWKolOkk0KKOxddxkkkkdooxkkxxxkOOOOkc. .,;,....   .,'.   .......        //
//    o:....',;cldk0XWMMMMMMMMMMMMWWNNNWWWNNWMXOOkxk00OOOOOOkkkxxddkOxooxOkxo,...,;;'.    .;ll:.      ...         //
//    00OOO0XNNWWMMMMMMMMMMMMMMMMMMWWWNNWWMMMMMWNKkdxolodxxk0KOxdoloddl:,;;;',,;,''..  ..,:cc,.       ...         //
//    WWMMMMMMMMWMMMMMMMMMMMMMMMMMMMMWWNWWMMMMMMMWXOxdl:;;cxK0Ox:...,lol:;:c::;,',;,'.'''......      .....        //
//    WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMMMMMMMWN0dllcoxxo;....,:oxdc;;;,;;:cc;'..........   .....,,;        //
//    NNWMMMMWWMMMMWXOONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0x:....';lddc,,:ll::llc::::,.      .    .:llcldkkd        //
//    WWNNWWMMMMMMMWklxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOOxlcoddo:;;;cl:;cl:,,;;,..        .:dxoclk000k        //
//    MMMWNNWMMMMMMWXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN00Okkxodxxdc:c:;,''...        ,xOkxolclllod        //
//    MMMMMWWNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMWX0Oddk00Oxxxool:;:,.     .'lO0kkxdlccccc        //
//    MMMMMMMWNNWWMMMMNX0OkkKWMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNX0kdddxxdlokxddokkl,.    .ckO0OOOxdlc:::        //
//    MMMMMMMMMWNNWMMW0xoood0WMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWNX0Oxoooloddddoccxkxdox0d:'.    :O00KK0kkxoool        //
//                                                                                                                //
//                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TBF is ERC1155Creator {
    constructor() ERC1155Creator("To Be Found", "TBF") {}
}