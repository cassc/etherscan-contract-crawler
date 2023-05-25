// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ben Tolman
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    ________________________________________________________________________________    //
//     .;kWMMXd'...'lONMMXkl,.....':ldkOKKXNNNNNNNXK0kdl:,.   .'ckXMWXx:.  .,xNMMKl.      //
//    .lXMMNx,....oKWMNOo,. ..,ldOXWMMMWNK0OOOOO00KXWMMMWN0xc,.   'l0WMWO:.  .;OWMWk;.    //
//    xWMMKc. ..lKWMXx;.  .,lONMMWXOdl:,'..........';cox0NWMMNOl'   .cOWMNk;.  .lXMMXl    //
//    WMWO,  .;OWMNk,....:kNMMNOo:'.    ......'.....   ..,cxKWMWXx;.  .c0WMNx'   ;0WMN    //
//    MNd.  .oXMMK:. ..c0WMWKd,.  ..;ldk00KXXXXXKK0Oxoc,.. ..ckNMMNx,   .dNMWK:.  ,OWM    //
//    Nd.  'xWMNx'  .;OWMW0l'. .'ckKWMMMWNXKK000KXWMMMMN0d:.  .;xXMMXo.  .:KMMNl.  'OW    //
//    d.  'kWMNo.  .oXMWKl.  .:xXWMWXkdc;,'......';cokKWMMW0l'. .;kWMWO,   ,OWMXc.  ,0    //
//    .  'kWMWd.  'kWMNx'. .:OWMWXx:'.  ..','',''... ..;dXWMWKo.  .lXMMK;   'OWMXc   ;    //
//      .dWMWx.  ,OWMNo. .'xNMMKo'. .,lx0XNNNNNNXK0xl;.  'oKWMW0;. .:KMMK:   ,0MMK,  .    //
//      :XMMO'..'kWMNo.  ,OWMNx'. .:kWWMMMMMMMMMMMMMMN0c...,xNMMXc.  :KMMK;   lNMWx.      //
//     .kWMXc...oWMWx.  ,OWMXl. .;kNWWMMMMMMMMMMMMMMMMMW0:...oNMMXc. .lNMMk.  .kMMK;      //
//     ;KMMk...,0MMK;. .xWMWd...:KMMWWMMMMMMMMMMMMMMMMMMMXl...oNMMK,  .kMMNc   cNMWd.     //
//    .oWMWo...cNMMx.. ;KMMO' .;0MMMWWMMMMMMMMMMMMMMMMMMMMXc. .kMMWd.  cNMMx.  '0MMO.     //
//    .xMMN:...dMMNl. .oWMWo. .oWMMMMMMMMMMMMMMMMMMMMMMMMMMk...lNMMk.  ,0MM0'  .kMMK,     //
//    'OMMK;  .kMMX:. .xMMX:  .xMMMMMMM   MMMMMMMMM   MMMMM0,. ;XMM0'  'OMM0,  .kMMK;     //
//    .kMM0,  .kMMX:  .xMMN:  .xMMMMMMM   MMMMMMMMM   MMMMMO,..:XMM0'  'OMM0'  .kMMK;     //
//    .kMMK; ..dWMWo. .lNMWd. .lNMMMMMM   MMMMMMMMM   MMMMM0;..dWMMk.  ;KMMk.  '0MM0,     //
//    .oWMNl.. :XMMk.  ,0MMK;..,0MMMMMMMMMMMMMMMMMMMMMMMMMMNo.;KMMNc  .oWMWl   :XMMk.     //
//     ;KMMx.  .xWMX:  .lNMM0;.,0MMMMMMMMMMMMMMMMMMMMMMMMMMMk:kWMWd.  ,0MM0'  .dWMNl      //
//     .xMMX: . ;KMMO,  .oNMMK:;0MMMMMMMMMMMMMMMMMMMMMMMMMMMNXWMWx.  .kWMNc   ;KMM0'      //
//      :KMMk.  .lNMWk'  .lXMMN0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx. ..dWMNo.  'OWMNo.      //
//      .oWMWd.  .oNMWO,. .;OWMMMMMMMMMMMMM       MMMMMMMMMMMWKc. .'xWMWd.  .xWMWk.  .    //
//    .  .xWMNd.  .lXMMKc. ..cOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl...:0WMNd.  .dWMWO,  .o    //
//    l. .'xWMNd.  .:0WMWk;...,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo.,xNMMKc.  .xWMWO,  .lN    //
//    Xl.  .oNMWk'   .dNMMNk:.:KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKkXMMNx'   ,OWMWk'  .lXM    //
//    MNo.. .lXMW0c.  .,xNMMW00WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx,   .oXMMXo.  .lXMM    //
//    WMWx'...:0WMNk;.  .,dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;   .:OWMNk,.  'xNMW0    //
//    oNMW0:. ..lKWMNk:.  .lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkl;lOWMW0:.  .:0WMWk'    //
//    .:0WMNx,...'oKWMNOcckNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMKl.   'xNMMXl..    //
//      .dXMMXd'. .'l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;..'oKMMWk,       //
//    .  .,xNMWKd'   :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKodKWMWKc.  .:    //
//    k;.  .;kNMMXx;;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l.   ,kN    //
//    MNk;.  .,dXWMNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:.   'dXMM    //
//    NMMNk:.   'lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,  .,dXMMWO    //
//    ,xXMMWOl'.  .lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:.:kNMMNO:.    //
//      'oKWMWXx:. :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK0WMMXx;.      //
//    .   .ckNMMW0dkWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl'.  .:    //
//    Ol.   .,lkNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd,.  .'o0W    //
//    MMXx:.   .,ckNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO' ..:kXMMW    //
//    NMMMWO:.  . .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMBENTOLMAN2022MMMMO'.c0WMMMNk    //
//    ________________________________________________________________________________    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract BENT is ERC721Creator {
    constructor() ERC721Creator("Ben Tolman", "BENT") {}
}