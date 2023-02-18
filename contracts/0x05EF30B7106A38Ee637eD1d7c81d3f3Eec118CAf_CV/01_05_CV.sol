// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cosmic Visionaries
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//    ;:cclllooooddddxxxkkOOOO000OOOOkkkxxddddoolllcc::;;;,,,,,,,,,,''...........    //
//    :cllooooddddxxxxkkOO000KKKKKK000OOkkkkkxxddoollcc::;;;,,,,,,,'''...........    //
//    :cloddddxxxxkkkkOO0KKXXXXXNNXXXXKK00OOOOOkxxddoolcc::;;;,,,,,''............    //
//    :cloddxxxxkkOOOO00KXNNNWNKOkOKNNNXXKKK000OOkkxxddolc::;;;,,,'''............    //
//    ;:lloddxkkkOOO00KKXNWWWNk;',;lONWNNXKKKKK00OOkkxxdolc::;;;,,'''............    //
//    ;:cloodxxkkOO000KXNNWWM0;..',,:OWWNNKK00OOOOOOkkxxdolc::;;,,'''............    //
//    ,;:cllodxkkOO00KKXNNWWWO'..''.'lO00kl::,';:coxkkkxddolc::;;,'''............    //
//    ',;:cllodxkkO00KKXXNWWWXl...... ....        ..,codxdoolc:;;,,''............    //
//    '',;:cclodxkOO00KKXXNNNWX:.....                'lxxxdolc:;;,,''''..........    //
//    .'',,;:cloxkkO000KKXXKOo;. ....                .:oxxdolcc:;,,,,'''''.......    //
//    ..'',,;:clodxkOO00KXk:'.    .........            .':loolc::;;,,,,,,'. .....    //
//    ...'',,;:clodxkO00kl'.     .....',,,....           ..,;,,,''...........'','    //
//    ....'',,;::cloxkOOO:      .....,:lll;'..  .:c;'....           ....',,;,,,,,    //
//    .....''',,;:clodxkl.  ....,:lc;lk0KOl;'.  'xK0kxdolc;'......',;:::::;;;;,,,    //
//    ......''',,;;:coo:.    ...'lOK0KWWNx,.....;OK000OOkOkxolclloollcccc::::;;;;    //
//    .......''',,;;:c:. ....:l,..,xK00Kx;......oKXKK00OOOOOOkkxxddooollllcccc:::    //
//    .......'''',,;;,....':lddo;..':;,,,'.....;ONXXXKK0000OOOOOkkxxxdddoooolllcc    //
//    .......''''''.....';loooool'...........',xNNNNXXXKKKK00000OOOkkkxxxdddooool    //
//    ................,:cllllooool,.........'':ONNNNNXXXXXKKKKK0000OOOOkkkxxxdddd    //
//    .............',::ccccllllooooc'.........'l0NNNNNNNXXXXXXKKKKK0000OOOOkkkkxx    //
//    .........'',;;;::cccclllllllll,...........l0NNNNNNNXXXXXXXKKKKKK0000OOOOOkk    //
//    ...'',,,,,;;;::::ccccccllllllc.............cOXXXNXXXXXXXXXXXKKKKK00000OOOOO    //
//    .',,,,;;;;:::::ccccccllllllll,.............'ckKXXXXXXXXXXXXXXKKK000000OOOOO    //
//    ',,,;;;:::ccccccclllllllllll:................:kKXXXXXXXXXXXXXKK000000Okxxkk    //
//    ',,,;;::cclllllooooooooooool,.................;d0XXXKKK000KKKK00OOOOkxdddxk    //
//    ',,,,;::cllooodddxdddddddddl'.................';x0KKKK0OOkOOOOOOkkxdddddddd    //
//    '''',,;:cclloddxxkkkkkxxxddl'..................,cxOKK0Okkxxxkkkkxddooddddoo    //
//    ''''''',;:clloddxkkkOkkkkxxl....................;odk0OOkxxxxxxxddoooooooolc    //
//    .......'',;:ccloodxxkkkkkkxc....................':lodxxxxxxxxddolllccccc::;    //
//    ..........',,;;:cloodxxxxxxc.....................,;:lodddxxxxdlcc:::;;;;;,,    //
//    ............'',,;:cloodxxxxl'.....................',:cloooddolc::;;;,,,''''    //
//    ...............'',;:cloodddl,......................'';:clloollcc:;,,'''....    //
//    ..................'',;:cllll;........................',;:ccclllc;,'''......    //
//        ................'',,;;::;'......';,................',;;:cc:;,'.........    //
//             ................'''''......';;;'...............',,,;,''...........    //
//               ...........................',,'................''''.............    //
//                 ..............................................................    //
//                  .............................................................    //
//                                                                                   //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract CV is ERC1155Creator {
    constructor() ERC1155Creator("Cosmic Visionaries", "CV") {}
}