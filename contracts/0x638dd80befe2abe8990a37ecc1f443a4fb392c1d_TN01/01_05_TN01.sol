// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Trent North 01
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    lllllllllllllllllllllllllllllllllllllllloooddxxxxxxxxdddooolllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllloodxkO0KXXNNNWWWWWWWWWNNNXKK0Okxdollllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllloxk0KXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKOkdolllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllloxOKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kdolllllllllllllllllllllllll    //
//    lllllllllllllllllllllok0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKOxollllllllllllllllllllll    //
//    llllllllllllllllllox0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdolllllllllllllllllll    //
//    lllllllllllllllldOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXNMMNKkolllllllllllllllll    //
//    lllllllllllllldONMMMMMMMMMMMMMMMMMMWNNNWMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMNKko::OMMMMWXkolllllllllllllll    //
//    lllllllllllldONMMMMMMMMMMMMMMWX0kdlc:::cldxOKOdONMMMMMMWXKKNMMMMMMMMNOc'...'cxXMMMMWXkolllllllllllll    //
//    llllllllllokXMMMMMMMMMMMMMXkdl;'...........''',oxxkxdol:;,':oooONWXx:'........:0MMMMMWKxolllllllllll    //
//    llllllllldKWMMMMMMMMMMMMW0c....................',..............,ll;'...........lNMMMMMMNOollllllllll    //
//    lllllllokNMMMMMMMMMMMMMXd,.....................................................,ckNMMMMMWKdlllllllll    //
//    lllllloOWMMMMMMMMMMMMMKc......................................................,cd0WMMMMMMMXxolllllll    //
//    lllllo0WMMMMMMMMMMMMMXl................................................';coddkXWMMMMMMMMMMMNkollllll    //
//    llllo0WMMMMMMMMMMMMMMO,................................................,xNMMMMMMMMMMMMMMMMMMNkllllll    //
//    llloOWMMMMMMMMMMMMMMMk'................................................,OMMMMMMMMMMMMMMMMMMMMNxlllll    //
//    lllkNMMMMMMMMMMMMMMMMO,................................................lNMMMMMMMMMMMMMMMMMMMMMXdllll    //
//    lldXMMMMMMMMMMMMMMMMMXl...............................................;OMMMMMMMMMMMMMMMMMMMMMMM0olll    //
//    lo0WMMMMMMMMMMMMMMMMMMKo:'...........................................'dWMMMMMMMMMMMMMMMMMMMMMMMNklll    //
//    lxXMMMMMMMMMMMMMMMMMMMMWNOc'..........................................,xNMMMMMMMMMMMMMMMMMMMMMMMKoll    //
//    oOWMMMMMMMMMMMMMMMMMMMMMMM0;...........................................'oXMMMMMMMMMMMMMMMMMMMMMMNxll    //
//    oKMMMMMMMMMMMMMMMMMMMMMMMMXc.........................,::'...............'oXWMMMMMMMMMMMMMMMMMMMMWOll    //
//    dXMMMMMMMMMMMMMMMMMMMMMMMMXc.....................',ckKNKc.................;dXMMMMMMMMMMMMMMMMMMMM0ol    //
//    xNMMMMMMMMMMMMMMMMMMMMMMMM0;....................,dKNMMMWx'..................;OWMMMMMMMMMMMMMMMMMMKdl    //
//    xNMMMMMMMMMMMMMMMMMMMMMMWk:'....................:ONWMMMMKd:'.................'oXMMMMMMMMMMMMMMMMMKdl    //
//    xNMMMMMMMMMMMMMMMMMMMMMWx,.......................;lOMMMMXxx:...................lXMMMMMMMMMMMMMMMMKdl    //
//    xXMMMMMMMMMMMMMMMMMMMMWO;.........................':kNMMK:ok;..................'oNMMMMMMMMMMMMMMMKol    //
//    dKMMMMMMMMMMMMMMMMMMMNx;............................':xXXc:0d'..................,kWMMMMMMMMMMMMMM0ol    //
//    o0MMMMMMMMMMMMMMMMMWO:'................................;c,.:xl'..................cXMMMMMMMMMMMMMNkll    //
//    lxNMMMMMMMMMMMMMMMM0:.......................................','..................'xWMMMMMMMMMMMMKdll    //
//    loKMMMMMMMMMMMMMMMNl..............................................................lNMMMMMMMMMMMWOlll    //
//    llxNMMMMMMMMMMMMMMXl..............................................................lNMMMMMMMMMMMKdlll    //
//    lloOWMMMMMMMMMMMMMMx'.............................................................:KMMMMMMMMMMNxllll    //
//    llldKWMMMMMMMMMMMMWd..............................................................'oNMMMMMMMMWOollll    //
//    lllldKMMMMMMMMMMMMWd...............................................................,OMMMMMMMWOolllll    //
//    llllldKMMMMMMMMMMMNl...............................................................,OMMMMMMW0ollllll    //
//    lllllldKWMMMMMMMMMXc............................................................,:lONMMMMMWOolllllll    //
//    lllllllo0WMMMMMMMM0;...........................................':lccccclloooodxOKNWMMMMMMNkollllllll    //
//    llllllllokXMMMMMMMO;........................................';okNMWWWWWMMMMMMMMMMMMMMMMWKxllllllllll    //
//    lllllllllld0WMMMMMK:........................................lXMMMMMMMMMMMMMMMMMMMMMMMMNOolllllllllll    //
//    llllllllllloxKWMMMXc.......................................lXMMMMMMMMMMMMMMMMMMMMMMMN0dlllllllllllll    //
//    lllllllllllllokKWMMO;.....................................'xWMMMMMMMMMMMMMMMMMMMMMN0xollllllllllllll    //
//    llllllllllllllloxKNNo.....................................'xWMMMMMMMMMMMMMMMMMMWN0dollllllllllllllll    //
//    lllllllllllllllllodOOxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkKMMMMMMMMMMMMMMMMMWKkdlllllllllllllllllll    //
//    llllllllllllllllllllox0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKOdolllllllllllllllllllll    //
//    llllllllllllllllllllllloxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kdollllllllllllllllllllllll    //
//    llllllllllllllllllllllllllldxO0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0kxollllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllodxkO0KXNWWMMMMMMMMMMMMMMWWNNXK0Okxoollllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllooddxkkkOOOOOOOOOkkxxdoolllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TN01 is ERC721Creator {
    constructor() ERC721Creator("Trent North 01", "TN01") {}
}