// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Special Moments
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ...        ..,.....,;,:oxo;..  ....:kXNWWX0kOXNKO000OkkkO00Oko;.........'.            .....:x0XKkc;,    //
//    ...         ;o,......':OWWKc'...;o0XKkxk0KkdxxdxOkxxllxdollkKXX0xl;'......            ....,dXXKOo;'.    //
//    '....        .    ....';ldo::cdOXX0koccclod0NOxOK0OOkolllddddxO0KXX0o,.            ......'';::;,'...    //
//    ,'....       ...........'',cx0XX0kxol:::::lONNKXNNNWWKxlccccccclodkKXO:.         ..........'''''.','    //
//    ;,'......................;dKXK0kxo:;::cc:cdkKN0OKKXXNNklcccc;,,;::lodOKd.      ...............''.',.    //
//    :;,'.......''...........c0NX0kxdl:,,,,cl::coOX0kO00KN0o:;;::,,,,,,;::lxKO,.........................'    //
//    olc;,'''''..''''''..',,lKNXKKKKxc;;,,;c:,codOKKK00XNXx:,,;,''''''.'',;lx00:..       .........',;;;::    //
//    :loolc::::::;;;cccc:ldkXNXX00Oko:;;;;;,;::cxkocdkkxxo:,'''.........'',;cokO;            ...',;:lkO0O    //
//    ,;;:lllllccccloxdoodkKWWNKOxdl:;;,:l:,;,,::;;;,,cc;,'''.'............'',:lxk,           ....',:xKXKO    //
//    :::cllolloollooooloxXMMNXOdlcc;,''.',,;,',;;''.';;'',,,''''.......''''',;:oxx,        ......';:cc::;    //
//    c:clodxkO00koc::::coKNX0Oxollcc:;,'',''',,,;,,,''''''''.......','..'',,,;:ldkd.       ......''',,'''    //
//    ....;:cok0Oxoc:;,'':OKkdooc:::::;,''..';;,;:;;,..............'co;..',,,;:cclxk,       .......',:;'..    //
//    ....,;;;;;::;,'''''l0Odl:,,;;;:;;,;,,,;cc;clcl:'......'..'''',,,'..,;,',;::cxO:..     ..............    //
//    .''',,''........',,oKkoc;,,,,'''''..',,;odlccllc;;;;,,,',,'''',,,,,;:;,,:cccxOc.       ...  .. ..       //
//    ..'',''........',;,d0o:;,,,,;''''''',;;,,;:ccl:;;;;;,,,;cdo:,,;,,;::cl;,;:ccdOc..        ..             //
//    .''....';;'','..','oOoc:;;;;;'.....',;:c;'colc;:oddc;,'',ll:::;,,;;:cc;,;::cdOc..                       //
//     ....;ccc;,......''lxoc;,,,''.....',,:lc:ooc;;,;llc;''''.';;::,,,'';:,,,;;:cx0l''....                   //
//      . .............. 'od:;,,''....',;;col,:xxc;;;,,;;;,',::;:col,,;;;:;,'',:co0O:;:'..''...               //
//             . ...      ;Od;,,''......'.l0o;xKx;.,;;:cc::cccc:,,d0xl:,,;,,,,,clx0c......','.....            //
//       ...               lKo;;,,,'......;o:,ll;''''',:cccodc;;,':ldl;'',;:::codko.        ...,;,.           //
//    ...,'....   .        .d0o:cccclc;,.......''''''..',,;ll,',,,,,,:coxOKOdooxkc.           ..:,....        //
//     .....    ....    ....;O0xkkxxOXXKkdl:;'.............',,:codk0KXWWMMW0xxOO:.                 .......    //
//     .''..'.....''.......''c0XOkddkXWMMMWNXKOxxddoooolloxO0KXNWMMMMMMMWNKkk0k,                    ..'c:.    //
//     .....'.........'...''',l0KOdodOXWMMMMMMWNNWMMMMMMMMMMMMWWMMMMMMMWX0kO0x'                       ....    //
//    ....'::;,'.............';ldkOkdxk0XXNWMMMMWMMWWMMMMMMMMMMMMMMMWNX0kkOk:.                                //
//    ...',;;,'...,;..........'...:x0K0kxxOXNNNWMMMNNWMMMMMMMMMMMMWX0kxO0kc.                                  //
//    ...........'ld:,,'........ ...':dk00OkkOKXXNWWNWWNNNWWNNNXXKOkkO0kc.                                    //
//      .........';;:::,.......  ..    .l0NKOxxxk0KK0KK000K0OOkkkOOK0x:.                                      //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SM is ERC721Creator {
    constructor() ERC721Creator("Special Moments", "SM") {}
}