// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BURIZU COLLECTION
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    0'        .c0WMMMMO.         .lKMMMMK,           .    //
//    0'          'kWMMMO.           ;OWMM0,           .    //
//    0'   'lol'   ,KMMMO.   ,oooc.   :XMMNkoo:.   'lood    //
//    0'   oWMWo   '0MMMO.  .xMMMNc   ,KMMMMMMK,   lWMMM    //
//    k.   cKXKc   '0MMNx.  .oXXX0;   ;KMMMMMMK,   lNMMM    //
//    .     ...    lNMNo.    .....   .oWMMMMMMK,   lWMMM    //
//                 oWMNl            ,xNMMMMMMMK,   lWMMM    //
//    o.   ;kkx;   ,0MWKl.   :oc.   lNMMMMMMMMK,   lWMMM    //
//    0'   oWMWo   '0MMMO.  .xWNo   'OMMMMMMMMK,   lWMMM    //
//    0'   ;kOx;   ,0MMMO.  .xMMK,   cNMMMW0OOd.   ;kOO0    //
//    0'          .dNMMMO.  .dMMWx.  .kMMMK;           .    //
//    K:........,lOWMMMM0;..'kMMMXc...lNMMK:...........,    //
//    WXK0OkkkkO0XXNWMMMWXK0O0XXXX0Okk0WMMW0kkkkkkkkkkk0    //
//    W0l,.........:KMMMW0c'..........cXMMXc...........,    //
//    X;           ,0MMM0,            ;KMMK,           .    //
//    0'   ;xkkkkkk0NMMMO.   :kkkkkkkk0WMMK,   ,xkkkkkkO    //
//    0'   oWMMMMMMMMMMMO.  .xMMMMMMMMMMMMK,   lWMMMMMMM    //
//    0'   ;kOOOOKNMMMMMO.   ckOOOOOKWMMMXd.   ,xOOOKWMM    //
//    K;         .;kWMMM0,          .:OWWd.         ;KMM    //
//    MKl'.....    ,KMMMWOc'......    :XWx.     ....:KMM    //
//    MMWNXKKKKc   '0MMMMMWNXKKKK0:   ,KMNk'   :0KKKXWMM    //
//    MMMMMMMMWo   '0MMMMMMMMMMMMNc   ,KMMK,   lNMMMMMMM    //
//    Nkooooooo,   '0MMMXxoooooool'   ,KMMK,   'loooooox    //
//    0'           cXMMMO.            lNMMK,           .    //
//    Xl,,,,,,,,;:xXMMMMKc,,,,,,,,,;ckNMMMXo,,,,,,,,,,,c    //
//    MWWWN0kkk0NMMMMMMWKOkOKWWWWNKOOOKWMMN0kkOKWWWXOkkO    //
//    MMMMO,   ;0MMMMMMK;  .oWMMMNl.  :XMMNl.  ;0MXc.  ;    //
//    MMMWo    .xWMMMMM0,   lWMMMNc   ,KMMM0,   cKo.  .k    //
//    MMMX;     cNMMMMM0,   lWMMMNc   ,KMMMWk.  .'.  .dW    //
//    MMMk.     '0MMMMM0'   lWMMMNc   ,KMMMMWd.      cNM    //
//    MMWl       dWMMMM0'   lWMMMNc   ,KMMMMMXc     ;KMM    //
//    MMK,       :XMMMM0'   lWMMMNc   ,KMMMMMM0'   .xMMM    //
//    MMx.  ..   .OMMMMK,   lWMMMNc   ,KMMMMMWx.    lNMM    //
//    NO;   .;.   :0WMMK,   lWMMMNc   ,KMMMMMO'     .xWM    //
//    0,           ;KMMK,   lWMMMNc   ,KMMMMK;       'OM    //
//    K,    ...    ;XMMX:   .;ccc;.   cNMMMNc   'd;   ;K    //
//    X;   ,OXk'   cNMMW0:.         .cKMMMWd.  .xWO'   c    //
//    K;...lNMNl...cXMMMMNx;.......;xNMMMMK:...lXMWd...,    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract BURIZU is ERC721Creator {
    constructor() ERC721Creator("BURIZU COLLECTION", "BURIZU") {}
}