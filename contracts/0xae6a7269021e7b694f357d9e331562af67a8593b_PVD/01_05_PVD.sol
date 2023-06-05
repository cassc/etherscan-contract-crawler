// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Peppa Van Drinkle
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                  //
//                                                                                                                                  //
//                                                                                                                                  //
//     _______                                   ____   ____                ______             _            __       __             //
//    |_   __ \                                 |_  _| |_  _|              |_   _ `.          (_)          [  |  _  [  |            //
//      | |__) |.---.  _ .--.   _ .--.   ,--.     \ \   / /,--.   _ .--.     | | `. \ _ .--.  __   _ .--.   | | / ]  | | .---.      //
//      |  ___// /__\\[ '/'`\ \[ '/'`\ \`'_\ :     \ \ / /`'_\ : [ `.-. |    | |  | |[ `/'`\][  | [ `.-. |  | '' <   | |/ /__\\     //
//     _| |_   | \__., | \__/ | | \__/ |// | |,     \ ' / // | |, | | | |   _| |_.' / | |     | |  | | | |  | |`\ \  | || \__.,     //
//    |_____|   '.__.' | ;.__/  | ;.__/ \'-;__/      \_/  \'-;__/[___||__] |______.' [___]   [___][___||__][__|  \_][___]'.__.'     //
//                    [__|     [__|                                                                                                 //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl,..   ..;o0NWMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl.  .,;;;'.  .lKWMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo. .:k0KK00xc.  ;OWMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;  ;OKKKKKKK0d.  ,OWMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:  'xKKKKKKKK0d'  ;0WMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx.  ;k0KKKKKKK0o. .oNMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx'  'd0KKKKKKKO;  ,OWMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk;  .o0KKKKKK0l. .xNMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:. .l0KKKKKKd. .oNMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK:  .dKKKKKKx. .lXMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMWk'  :OKKKKKx. .lXMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNOdllxKWMMMMMMMMMMMMK;  ,kKKKK0o. .dNMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c.    ,OWMMMMMMMMMMWO,  ;OKKKKO:  ,OWMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkdoxKN0;  .,. .oXNNNWMMMMMWXl. .o0KK0Kd. .lXMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:.   ,dc. .ox'  ':;,;oKWMMWXo.  cOKKKKk,  ,OWMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.  .  ..  ,O0o.       cKMWKc.  :OKKKKO;  .xNMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl. .c:.    ;OK0d, .c,  'k0d,  .lOKKKKk;  .dNMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNx.  :kkl:,,cOKKKOdxOo.  ..  .,d0KKKKk;  .dNMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKOdc'.  .:k00OOOOOO000KK0d;...':d0KKKKKk;  .dNMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc'..   ...',colllllllloddxkOOOkO00KKKKKKO:  .dNMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkc'    ..';:ccc:;;:cccccccccccclloxkO0KKKKK0l. .oKNKKKNWMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0o'.  .';;::::cccc;'.;ccc:;:cccccccccccldk0KKKO;  .;:,...;xNMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOc.   .,:cc:;:;''',,'..',,'..,:ccccccccc::ccoxOK0o'.   ..   ,0WMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l.  .';cccc:;;,..............'',:ccccc:;,'':cccoxO0Oxdddxc.  cKMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXd'  .';ccc:;;,','.....''''.....''..'',,''.'..';:cccox0KK0x:.  ,kNWMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:.  .;cc:;;,..'',,;;,;,',,'..,,'......'..........,:cccdO0k:.   .,:lkNWMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx'  .,:c:;,,,,'.. .','',,.....';;'............';;'..';cccok00kl:'.   .xNMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.  .;ccc:;;;,','...........'',,,,,,;;::::,.  .,:c:;''';cccok00ko:.   'kWMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.  .:ccccc:;:,,;;;,,;:;,.',;:cc::ccccc:,'..  ..':cc:,''',:ccc;'.   .,lONMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.  .:cccc:,;l:;c:;;,;;,''..',,,,,,,'.............,:cc:,;,.,:c:.  .:x0NWMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk'  .::::;;,.,;,;::;....  .. ............''...'.....;cc:;;;.':cc,  .dNMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0;  .;:;::,,;,,';::;'.    ....,'........':cc:,.,,...';ccc;;:,',:c;.  :KMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.  ,cc::;,'..'';c:,.    .. .,'..........;;;;;;;,...',:cc;::...;c:.  'OWMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk'  .:ccccc;,'...'::,.   ........','..''..',;:::::;'.';:c::c, .';cc'  .xWMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc. .;cccccc;;:....,c;.   ..;;.......'..''';:cccc::;,..::c:l:...,:cc'  .dNMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx.  ':cccccc;;;,'...,;,.....;c;...........',,;:::cclc'.;:clc'';,;ccc'  .xWMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:  .;ccc:::::c:;::,...,'.....................,::'......:loc,.';;:cc:.  'OWMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.  'cccc:cccc:;;,'..................',,'.','':ld:...'..:c:cc;,;:ccc:.  ;KMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0;  .;cc::;;;;;,'''.'..........';,'........';',cdl..','.''..,;;::cccc;. .lXMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.  'cccc:;;,'.......',;........,,;;;,;'...',,;oo'.';;,,:;'',,';ccccc'  .xNMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:  .;ccc:;:::'.... ..,:::;,,,,.......''..',,,;cc,.,:;,,:c:;,''..;ccc;.  ;0WMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx.  'ccc:;,.,;'';::. ..',;::;,,,,'....'....'';:;...,;::;;:::,,;,,;cc:.  .xNMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:  .;cccc:,.':;::;;,. ..,;;;;,,;;;,,,,''....,'...,,;;,;;;;;;;;cccccc,  .lXMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx.  'cc::;;,.'::::'..  .,:cc::;;;:;,,''''...... .;;;;;;;;,,,,,;:cccc,.  :0WMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:  .;cc:;''''.;:;;'....',;::;;;,,'''''''.....'....';;;;;;;;;;:::ccc;.  ,OWMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.  'cccc:,'....,;;,,..','...''.....'..'.  ........',;,''.';:;:cccc;.  'kNMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK:  .;c:::;,.... ..,,,'..,;..  ....  ............'',,,....',,:ccccc;.  'xNMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx.  'cc:;;;;,...... ..'..;;,'.  ......',,,,,,''',,'.',',:c:;:ccccc;.  .xNMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWK:  .;ccc:,.,,,,',;;,'...';;;'.....'...',,,;;,'',',;,,llllc:cccccc;.  'xNMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.  'ccc:;,....'',,,,,'. .,;,.':::'........';;::oolol::c:::cccccc;.  'xNMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWO,  .:c:;;;:;.. .........  .,..',,,,''...'.    .',:l:;;;:ccccccc:,.  ,kNMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMXl. .,cc;,,;ll,...'......''.............''.'.   .';oo::::ccccccc:'   :OWMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNx.  .:ccccc:;;;,...'....'::'................'.   ':c:::::cccccc;.  .lKWMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWO;  .;cc:;;;;'.';,.......',.........''''...',;,'...,:ccc:ccccc:,.  'dXWMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMWKc. .,ccc:;;,'',;;,. ..;;,....''''...'''..';cc;'.,;'';cccccccc:'   ;ONMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMXo.  ':cc:;;;,'''.... ..'',............'..'cc,..,,,;:;:ccccccc;.  .lKWMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMNd.  .:ccc:;...............,,..  .......,.,:,.'''.,::cccccccc:'.  ,kNMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMNx'  .:cc:;::;'.  .',......,;'...,;'.....,,;,.'',,',:ccccccc:,.  .lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMNx.  .;cc:,,;,,,'.';;'..,,',,....',,,,,;'.''',;,..',;:cccccc;.  .;kNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMNx.  .;cc:,'.','':c:;'............''....'',',,,;;,,;;:ccccc:'.  'dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMNd.  .;ccc:,,'.''',;'...........'..,:,'....,;:,';::ccccccc:'.  .l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMXd.  .;ccccc;;;'''........'....'''..,;;,....';:;;::cccccc:,.  .:ONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMXo.  .;cc::c::;,,;'...''.......','...'''''....',:ccccccc:,.  .;kXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMWKl.  .:cc:,',,;;,,'...';,'',::,,;,...'..,;;,',,;;:ccccc:,.  .;xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMW0:.  ':ccc;'..''',,,.. .';::::;,,,..',,',;;:;,;ccccccc:'.  .;xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMNk,  .,:cccc;...',,,;,...'::;,.......,;;,',;;;:ccccccc;'.  .:kXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMWXd'  .;cc::c:,'..,,'.''..';,''..',,'.,:c:,',;;:lllll:;..  .cONWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMW0c.  .;c:,,;ccc:'.''......''..........,:cc:;:cloddo:,.   'o0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMNk,  .':c;,',;;,,'...,'.  .....  .,'''';:ccccclooo:,..  .;dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMNd.  .;cc:''''........'......',''',,,'',;cccclooc,.    .ckXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMNx'  .;ccc;.......;;;'..',;,,;cc:ccc:;;,;:clllc;..  .';dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMWO,  .;cc::,..''..',::,..',,,;:::cccccccclllc;..  .,oOXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMW0:  .,ccc;,,'..'...',,'....',;:ccccccclllc;..  .'lkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMNd.  'cccc:,,,,;;:,..... ..,::ccccccllc:,..  .'ckXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMNo.  ,cccccc:;'''',,'....';cccccclc:,..   .,lkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMNd.  ':ccccccc:;,,,,;;;,;:ccc::;'..   ..;oOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMWK:.  ';cccccccccccccc::;;,'...   .':okKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMWKl.  ...',,;;;;,,,'....    .';lx0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMNOl,..             ..';cdk0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    WWWWWWWWWWNKko:,........',:ox0XWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW      //
//                                                                                                                                  //
//                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PVD is ERC721Creator {
    constructor() ERC721Creator("Peppa Van Drinkle", "PVD") {}
}