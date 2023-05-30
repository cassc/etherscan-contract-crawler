// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Glimmer
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXKKKKKKKKKKKXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXK0OkxdooolllllllooollodxxkO0KXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNX0kxdolcccccccllcllllccllccccclllllodxO0XNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNX0kdolccllllllllllooooolllllllllllollllccccldxO0XNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNXOxdoccllllooooolooooodxdddddddooddddoddoooolllllcldk0XNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNX0xolclloooooodddddddoolcclccccccccclodxdxxxddddoooollllldOKXNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNXOxlllloddoodddxxdlcc:;;,,',''''','''',,,;;:clodxxddddooooollox0XNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNKOdoloodddxxxxddoc:;,,,,,;;,;;,;;;;;;;;;;;,,,,,,;::codxxxdddoooolldOXNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNXOdlloooodddxxol:;,;;;;;;;;::::::cc::cccc:::::::;;;;,,;:codxxxxddooolod0XNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNN0xoloooddddxxo:;,,;;;:c::ccccclllllccclllllllccccc:::;;:;;;;cdkkxddddooookKNNNNNNNNNNNN    //
//    NNNNNNNNNNNXkooooddxxkkxl:;,;:::cccllooll:;;,,,'',,,'',,;;::lollcccc:::;;,;coxxxxdddooox0XNNNNNNNNNN    //
//    NNNNNNNNNNKxooddxxkkxxo:;;;:ccccllllc:;''...................',;:llllccc::;;;;:dkxxxddddddOXNNNNNNNNN    //
//    NNNNNNNNX0xoddddxxkkoc;;:::clllooc;,.....'''',,,,,,,,,,,'''''...',:lolllcc:::;;ldkxxxxdddoxKNNNNNNNN    //
//    NNNNNNNN0ddddxxxxkkl:;::ccclool:,...'',,,,;;:::::::::;:::;;;,,,,'..',cloocccc::;:okkkxxxdddxKNNNNNNN    //
//    NNNNNNN0xdddxxxkkxl:::cclloooc,'.'',;;;:::lllc:::;:;;::ccccc:;;;,,''..,coolllcc:;;lxkxxxxxddkKNNNNNN    //
//    NNNNNNKxdddxxkkOxc;::clloool,.'',;;;:cccc:,'.............',:cccc:;;,''.';looollc:::lkkkkxxxddkXNNNNN    //
//    NNNNNXkdddxxxkkxl:ccclooooc'.,,;;:ccll:'.. ..................,:llc:;;,,'.,ldoolccc::okkkkxxxddONNNNN    //
//    NNNNNOddxxkkkkkl::ccloooo:'.',;:::ll;........'''',,,,,'...... .':llc:;;,'.'cddollccccokkkkkxxdxKNNNN    //
//    NNNNKkdxxxkkOkdc:clloodd:'',,;:cll:......',,;::ccccccc::;,'......'colc:;,'''cdooolccclxOkkkkxxdOXNNN    //
//    NNNN0ddkkkkkkkl:cllloodc'',;;:clo:.....',;:llc;,'''',,:clc:;,'.....colc:;,,',ldooolccclkOkkxxxdxKNNN    //
//    NNNXkdxxkkkOOdccllloodo;',,;cclo:.....';cll;..         .':ol:;,.....colc:;,,';odddolcccxOkkkkkxxOXNN    //
//    NNNKkxxxkkOOOo:cllloddc,,,;:cloc'...',;clc.   ........    ,olc;,....,oocc:;,',lddollcccdOOkkkkxdkXNN    //
//    NNNKkxxxkkkOklclllodxd:',;:cllo;...',;:ll.   .,:loddl;'.   ,ooc;'....colc::;,'cddooolccokOOOOkxdkXNN    //
//    NNNKxxkxkkOOklcloodddd:',;:cloo,...',:lo:.  .,lk0XXK0xc'.  .coc:,....:oolc:;,'cxxddolcclkOOOOkxxkKNN    //
//    NNNKxxkkkkOOklclooddxd:',;:cloo,...';clo:   .,oOKXXXKkc'.  .coc:,'...:dolc:;,,:dxddollcokOkkOkkkkKNN    //
//    NNNKkxkkkOOOkocllodddd:,;;:clod:...',:col.  ..,ldxkxoc,.   ,ooc;,'...collc:;,,cxxddollldOOOOOkkxkXNN    //
//    NNNKkxkkkkkOOoclloddxxl,;;:clldl...'';:loc.   ...'''...   'lol:;'...,oolc:;;,,oxddoollcdOOOOkkkkOXNN    //
//    NNNXOxxkkOOO0xllooodxxd;,;:cclod:...',;:lol;.          ..:ool:;'....cdolc:;;,:dxdooolllxOOkOkkkx0XNN    //
//    NNNN0xkkkkOO0kolooddxxxl,,;:cllod:...'',:clooc;,'',',;:lollc:;,....cdoolc:;,;oxdddoolloOOOOkkkkkKNNN    //
//    NNNNKkkkkkOOOOxolooddxxxc,,;clllodc'...',;::ccllooooooolc:;,,'...,lddolc:;;;lxxxddoollxOOOOOkkkOXNNN    //
//    NNNNX0kkkkkOOOOdlloooddxxc,;::cllodo:....'',,;;;:cc::::;,,'....'cdoollc::;;lxxxddoollxOOOOkkkkkKNNNN    //
//    NNNNNXOxkkOOOOOkoloododxxxl;;;;ccloodoc,.....'''',,,''''.....,codoolcc::;:oxxxddoolldOOOOOkkkk0XNNNN    //
//    NNNNNNKOkkOOOOOOkoloooddxxxo:;;:::clloddoc;,'...........',;clddollcc::;;cdxxxddoolldkOOOOOkkkOXNNNNN    //
//    NNNNNNNKkkkkOOOOOkdllooddxxxdl:;;:::clloooddollccccccclooddoolllcc::;;:oxxxdddoooldkOOOOkkkkOKNNNNNN    //
//    NNNNNNNNKkkkkkOO00Odlloooddxxxxl:;;::cclllloooooooooooooolllccc:::;;coxxxxdddoollxOOOOOOOkkOKNNNNNNN    //
//    NNNNNNNNNKkkkkOOOOOOkolloodxxxxxxdc:;;::::cccclllcclllclcc::::;;:cldxxxxddooolldkOOOOOOkkkOKNNNNNNNN    //
//    NNNNNNNNNNKOkkkOOOOO0Oxoloooddddxxxxdlc::::;::::::::::::;;;;::cldxkxxxxxdoooloxO0OOOOOOkkOXNNNNNNNNN    //
//    NNNNNNNNNNNX0kkOOOOOOOOOxolloooodxxxxxxxdoolllcc::::cccclllodxxxxxxdxdooooodkO0OOOOOkkOO0XNNNNNNNNNN    //
//    NNNNNNNNNNNNNKOOkOOOOOOOOOxdoooodddxxxxxxxxkxxxxxxxxxxxkkxxxxxdxxddodoolodkO0OOOOOOkkkOKNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNX0OkkOOOOOOOOOkxdooooddddxdddxxxddxxxxxxxxxxdddooodoooooxxOOOOOOOOkkkkOKXNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNX0OkkkkkOOOO000OxxdolooddooddoooddddddddoddoollllodxkOO0OOOOOkkkOkOKXNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNX0OkkkkOOOOOOOOOOkkxxddoooollloollloooloooodxxkkOO0OOOOOOOOkkkOKXNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNXK0kkkOOOOOOOOOOOOOOOOkkkxxxxxxxxxxxxkkOO000OOOOOOOOOOkkkO0KXNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNXK0OkkkkkOOOOOOOOOOOOOO0000OO0000OOOOOOOOOOOOOOkkOOO0KXNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNXK0OOkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkk0KXXNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXK00OOkkkkkkOkkkkOOOOOOOOOOOOOkkkkOOO0KXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXKKK00OOOkkkkkkkkkkOOOO0000KKKXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXXXXKKKKXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GLMMR is ERC721Creator {
    constructor() ERC721Creator("Glimmer", "GLMMR") {}
}