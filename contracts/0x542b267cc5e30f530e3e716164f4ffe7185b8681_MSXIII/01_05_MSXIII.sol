// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MrSamsaraXIII
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//    MMMMMMMMMMMMMMMMMMMMMWWXKOdlc:;;;;;;;;;;;;:::;::;;,',oONMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWKkoc::;,';:;coxO0KKXNNNWWWWWWWWWWWWN0o;.;dXMMMMMMMMMMMM    //
//    MMMMMMMMMMMWXx:..,cooodkKWWMMMMMMMMMMMMMMMMMMMMMMMMMMNOc.,kWMMMMMMMMMM    //
//    MMMMMMMMMNOl. .l0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx'.oNMMMMMMMMM    //
//    MMMMMMMWk,. .l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'.xMMMMMMMMM    //
//    MMMMMMWx. 'dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.;KMMMMMMMM    //
//    MMMMMWx..:0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl.cXMMMMMMM    //
//    MMMMM0,.dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMNl.oNMMMMMM    //
//    MMMMNl.dNMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMN0kdool;,ckXNWMMMMK;'0MMMMMM    //
//    MMMWk'lNMMMMMNd;:olccodxkO0XWMMMMMMMMMMMMWd..;codxdc::::lkXMWd.:KMMMMM    //
//    MMMK,;KMMMMWO;            ..;lkXWMMMMMMMMWx.cNMMMMMMWX0o..oWMX;.xMMMMM    //
//    MMWd.lWMMMWx.   ;ddxxkkxddddl;',:o0NWMMMMMO':NMMMMMMWKX0, dWMK, dWMMMM    //
//    MMWl lWMMMWx. .dXMMMMMMMMMMMMWXOo'.'oNMMMNl.lNMMMMMNkcxK;.kMWd..OMMMMM    //
//    MMWo 'OMMMMX; oWMMMMMMMMMMMMMMMMNc..cNMNOc':dOXWWWXdcdXWo.xMX: cNMMMMM    //
//    MMM0' ;KMMMX:.kMMMWWWWWWWWWWWMMMO.'o0W0c,l0Xkllok0dckNMM0,lNX;.xMMMMMM    //
//    MMMWx..xMMMO'lNXOxxxddddddddd0WM0',dKWo.lNMMWN0dc;;l0WMMNc;KWl.kMMMMMM    //
//    MMMMX;.kMMNc'OWXkxxxkkkkOOO00NWMWx,.cX0;'kWMMMW0lcolcoOXNo,OMk'oWMMMMM    //
//    MMMMN:.xWMX:.dWMMMMMMMMMMMMMMMMMMWkc,cXK:'xNMMXxdKNN0dc:o;,OMX:cNMMMMM    //
//    MMMMWx.;KMWO'.lXMMMMMMMMMMMMMMMMMMKk;.ld:..lXMWNNWKko:,;ccxNMNl:XMMMMM    //
//    MMMMMNl.:XMW0:.'dXWMMMMMMMMMMMWN0xc;,;cc;;;':KMMM0,'lk0XWWWMMNc;KMMMMM    //
//    MMMMMMXc.,OWMWO:.'cxkOOOkkxxxdoc;,;:ccc:;;oo.,kXO;.xWMMMMMMMMK; cXMMMM    //
//    MMMMMMMNd..c0WMWKxllooool;''',:;,,,,;;,,,,ckx,....lNMMMMMMMMNl  .dWMMM    //
//    MMMMMMMMW0c..xNMMMMMMWNkcc:,,,;,,,,,,,,,,,,l0Kkxk0WMMMMMMMMXo. ,''OWMM    //
//    MMMMMMWXxlc,.:KMMMMMMXd;,cdl;,,,,,,,,,,,,clclxKWMMMMMMMMMWk,  ,Ok',OMM    //
//    MMMMWXx;.  .xNWMMMMMMNx:,,;ldl,,,,,,,,,;:lc;,:xNMMMMMMMMWO..,dXMWx.cNM    //
//    MMMNd'.   .kWMMMMMMMMMWKx:,ckd;,,,,',,,,::,:d0NWMMMMMMMMX:'xNMMMMX;,0M    //
//    MMXc.    ,OWMMMMMMMMMMMW0l:lc;,,,,,,,,,,;;,lKWMMMMMMMMMMO;dWMMMMMWo'kM    //
//    MX: .',;oKMMMMMMMMMMMMMWk::c;,,,,,,,,,,,,,,dXWMMMMMMMMMXlcXMMMMMMMx.lW    //
//    Nl'l0NWWMMMMMMMMWWMMMMMNx;,;,,,,,,,',,,,,,cOWMMMMMMMMMMOlOMMMMMMMMX;'k    //
//    d,xWMMMMMMMMMMMKldNMMMMWKdodc,,,,,,'',,,,,dNMMMMMMMMMMMWNWMMMMMMMMMO';    //
//    :oNMMMMMMMMMMMMO.'0MMMMMMWWWXkl;,,,,,,,;lxKWMMMMMMMMMMMWOkNMMMMMMMMWd.    //
//    'xMMMMMMMMMMMMMX;.kMMMMMMMMMMWXx:,;;;:lkXWMMMMMMMMMMMMWOlOWMMMMMMMMMO'    //
//    ':XMMMMMMMMMMMMWd.lXWMMMMMMMMMMWKO0KKKXWMMMMMMMMMMMMMWOlkWMMMMMMMMMMO'    //
//    d.lNMMWK0XWMMMWKl..';codkOKXXNNNNXKKOc;llc:lxXMMMMMMWk;;ooox0NMMMMMMk'    //
//    Nl.lXMWOocclll:....,kOkxxddxxxxxxdc'.'oddo:..'lkOOxo:,;cllc,',dXMMMWd'    //
//    MNo.lNMMMNKkdllokKd;xWMMMMMMMWWWWW0xd0MMMMWKd:,,:c:.;OWMMMMN0dxXMMMNl'    //
//    MMNl'kMMMMMMMMMMMMNo,kWMMMMMMMMMMMMMMMMMMMMMMWWWN0odXMMMMMMMMMMMMMMK;,    //
//    MMM0;;KMMMMMMMMMMMMK;'OMMMMMMMMMMMMMMMMMMMMMMMMMKxOWMMMMMMMMMMMMMMNo'd    //
//    MMMWk'cXMMMMMMMMMMMWd.lNMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMW0c;xW    //
//    MMMMWd'oNMMMMMMMMMMMNKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kolcoKWM    //
//    MMMMMNl'xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOlccclld0NWMMM    //
//    MMMMMM0',KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0OONMMMMMMMMWO,;xKNWMMMMMMMM    //
//    MMMMMMK,.dWMMMMMMMMMMMMMMMMMMMMMMMMMMMXx;..  'oOXNNWWXd:oXMMMMMMMMMMMM    //
//    MMMMMMNo..dXWMMMMMMMMMMMMMMMMMMMMMMMW0;  .,coc'.',;:ccl0WMMMMMMMMMMMMM    //
//    MMMMMMMNOc,;llcokKNWMMMMMMMMMMMMMMXOx'   lNMMWX0OOO0KNWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMWNK0kdc;;::cooooddddddddo'. ..:kNMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMN0xl,....         .':xKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract MSXIII is ERC721Creator {
    constructor() ERC721Creator("MrSamsaraXIII", "MSXIII") {}
}