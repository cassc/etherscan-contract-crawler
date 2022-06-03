// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Indi Sulta Guts
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    llllllllllllllllllllloxk0KXXXXXXXXXXXXXXXNNNNNX0kdllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllldk0XXXXXXXXXXXXNNNNNNNNNNNNNKOxdoolllllllllllllllllllllllll    //
//    lllllllllllllllllc;,:d0XXXXXXXXNNXXXNNNNNNNNNXXXXXXXK0Okdollllllllllllllllllllll    //
//    lllllllllllllllc;,;oOXXXXXXXXXXNXXXXXXXXNXXXXXXXXXXXXKKK0Odollllllllllllllllllll    //
//    llllllllllllll:'';d0XKKKXXXXXXXXXXXXXXXXXXXXXXXKKKKKKKKK0K0kolllllllllllllllllll    //
//    lllllllllllllc'.,o0KKKKKKXXXXXXXXXXXXXXXXXKKKKKKKKKKKK000000Odllllllllllllllllll    //
//    lllllllllllll,..;x000KKKKKKKXKKKKKKXXXXKKKKKXXKKKKK0000000OO0Odlllllllllllllllll    //
//    llllllllllll:...;okO00000KKKKKKKKKKKXXXXXXXXXKKKK000000000OOOOOxolllllllllllllll    //
//    looolllllooc,...'cxkOO000000000O000KKKKKKKKKKKK00000000000OkkOOOkdllllllllllllll    //
//    looolllllol:,'..';cdxO000000OOkkkOOOO000KK0000000000OOkkkkkkkkOOOOxollllllllllll    //
//    llllllllllc:,''',;cdk0000000OkkxkOOOOO00000000000Okkkxdlll:,,,;;;coollllllllllll    //
//    llllllllllc:,'',,:ok000000000OkkkkkkkOOOOOOOkoc;,''';cc;''...    'llllllllllllll    //
//    lllllllllll;'...';lO000OOOOOOOkxxdddxxxxxkxl,.      .';;,'......;ddlllllllllllll    //
//    lllllllllol;.....':xOOOkkkkkkkxdolcooooddl;..........;odol:'',:codolllllllllllll    //
//    lllllllllll,......'cdxxxdoodxxxdolcccc:;,'.':ool::;,:okkd:'.';;,;lllllllllllllll    //
//    lllllllllll:..  ...';coolccllodoolc:::'...';coo:;:l:;:lkk:...'.'cdolllllllllllll    //
//    llllllllllll'     ...,;c:::clloooolcc;.....',;,;:oo;.,oO0k:,;::clxxlllllllllllll    //
//    lllllllllllo:.     ....,;clollcccc:,,'....',:cloodoc;:okOOxollc::dxollllllllllll    //
//    lllllllllllll:.        .,cc;,,...........',;coddddxdlcclxkxdoc;,,:oollllllllllll    //
//    llllllllllllll:.       .,......   .........;ldxkkxxdc;:;,:ll;....;llllllllllllll    //
//    lllllllllllllllc'.     .'..':,.   .........',:looool;'.. .....',:lllllllllllllll    //
//    llllllllllllllllc'      ..''''..     ..........'''',;,.......,,:llllllllllllllll    //
//    llllllllllllllllll;.     .........           ....'...;cc,..,'';lolllllllllllllll    //
//    llllllllllllllllllll,.    ........ ....      ....'''';:;'.   .;lllllllllllllllll    //
//    lllllllllllllllllllll:'         .   .    ...       ...........;lllllllllllllllll    //
//    lllllllllllllllllllllll:'.       ....       ....    ..'.......;lllllllllllllllll    //
//    lllllllllllllllllllllllllc'.       .......   ...............';clllllllllllllllll    //
//    lllllllllllllllllllllllllll:..            ...     ......',:cllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllc,  .        ..........  .:llllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllo;.....         . ....'';llllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllo; ......      ......,lllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllll:.  .  ...    ..'...;llllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllloc'.   .        .....'clllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllloo:.                ...lolllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllol,.                 ..,lllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllll;.                     ,lllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllll;'.                       .:loolllllllllllllllllllllllllllll    //
//    lllllllllllllc:;;,'.                            .',;;:::ccllcclooooooollllllllll    //
//    lool:;;;;;,''....                                  ......'',,:lollllcoxdllllllll    //
//    loxxo:,.......           ....                          .....',;''''.'oxollllllll    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract INDIguts is ERC721Creator {
    constructor() ERC721Creator("Indi Sulta Guts", "INDIguts") {}
}