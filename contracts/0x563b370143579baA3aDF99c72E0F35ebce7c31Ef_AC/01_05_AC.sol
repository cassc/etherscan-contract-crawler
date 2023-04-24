// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alpha Camps
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    MWWWXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXNWWW    //
//    WN0l;,''''''''''''''''''''''''''''''''''''''''''''''''''''',,'',,,,,,,,,,,,,,,,,,,,'',:xXN    //
//    WK:.....................................................................................dW    //
//    W0,.....................................................................................oN    //
//    W0;...............................................'dd'..................................lN    //
//    W0;...............................................;KWO;.................................oN    //
//    W0;...............................................dWMWKc................................oN    //
//    W0;..............................................cXMMMMXl...............................lN    //
//    W0;.............................................:KMMMMMMXc..............................lN    //
//    W0;............................................:KMMMMMMMMO,.............................lN    //
//    W0;..........................................'lXMMMMMMMMMWd.............................lN    //
//    W0;........................................;kXNMMMMMMMMMMMK:............................lN    //
//    W0;......................................,xXMMMMMMMMMMMMMMWk'..:;.......................lN    //
//    W0;....................................'oXWMMMMMMMMMMMMMMMMXc..o0:......................lN    //
//    W0;...................................c0WMMMMMMMMMMMMMMMMMMWd..lX0;.....................lN    //
//    W0;.................................'dXMMMMMMMMMMMMMMMMMMMMMx..lNWO,....................lN    //
//    W0;...........................:,...'xWMMMMMMMMMMMMMMMMMMMMMMx..lNMWd....................lN    //
//    W0;..........................;0o...dWMMMMMMMMMMMMMMMMMMMMMMNo..oWMMX:...................lN    //
//    W0;.........................;OWd..lNMMMMMMMMMMMMMMMMMMMMMMMK;..xWMMWx...................lN    //
//    W0,.......................'lKWWo.,0MMMMMMMMMMMMMMMMMMMMMMMWd..,0MMMMK;..................lN    //
//    W0,......................,kWMM0;.lNMMMMMMMMMMMMMMMMMMMMMMMO,..oNMMMMNl..................lN    //
//    W0,.....................'kWMMWx..dWMMMMMMMMMMMMMMMMMMMMMMK:..cXMMMMMMx..................lN    //
//    W0,.....................lNMMMWo..xMMMMMMMMMMMMMMMMMMMMMW0:.'oXMMMMMMMk'.................lN    //
//    W0,.....................xMMMMWo..oWMMMMMMMMMMMMMMMMMMMNk,'l0WMMMMMMMMk'.................lN    //
//    W0;....................'kMMMMMx..:KMMMMMMMMMMMMMMMMMW0c;o0WMMMMMMMMMWd..................lN    //
//    W0;.....................oNMMMMK:..dWMMMMMMMMMMMMMMWOl,c0WMMMMMMMMMMMK:..................lN    //
//    W0;.....................'kWMMMWk'.'kWMMMMMMMMMMMW0c.'xNMMMMMMMMMMMWXl...................lN    //
//    W0;......................,kWMMMWk,.,kWMMMMMMMMMWk,.'kWMMMMMMMMMMMW0:....................lN    //
//    W0;.......................'l0WMMW0:.'dNMMMMMMMWx'.'xWMMMMMMMMMMN0l'.....................lN    //
//    W0;.........................'cxKWMNx;.:OWMMMWWk'..dNMMMMMMWNXOd:........................lN    //
//    W0;............................':ox00kl:lkNMKk:..cXNKOxdooc:,...........................lN    //
//    W0;......................,,'........,:ll:::dl;'..ld:'...................................lN    //
//    W0;....................'dXXK0Okxdlc:;'...................',;cclodxkx:...................lN    //
//    W0;....................dWMMMMMMMMMMWNK0kdoc;'....':odxkO0KXNWMMMMMMMK:..................lN    //
//    W0;....................oNWWWWMMMMMMMMMMMMMWNK0OxolllodxOKNWMMMMMMWXKx,..................lN    //
//    W0;....................':::cclox0XWMMMMMMMMMMMMMMWNKkdollllodddoc:,'....................lN    //
//    W0;......................':ldxoc;;cokKNWMMMMMMMMMMMMMMMWWXK0kxdl:.......................lN    //
//    W0;..................'coddodKWMWXOxlcclodkOKXNWWMMMMMMMMMMMMMNklccdkd'..................lN    //
//    W0;.................,kNMMWKccKMMMMWX0xc,...',;:cldxO0KXWWMMMMK::KWMMNc..................lN    //
//    W0;.................;0MMMMWo;kKkdl:,.................',:coxOKKccXMMNx'..................lN    //
//    W0;..................:x00kl'.,'.............................';'.cdo:....................lN    //
//    W0;.....................................................................................lN    //
//    WXl....................................................................................'kN    //
//    WWXkollllllllllllllllllllllllllllllllccccccccccccccccccccccccccccccc::;;::::;;;::::::ldOX0    //
//    WNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNNNNNNNNNNNNNNNNNNNNNXKK0KKXKKKKKKXKKXNNKOO    //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract AC is ERC1155Creator {
    constructor() ERC1155Creator("Alpha Camps", "AC") {}
}