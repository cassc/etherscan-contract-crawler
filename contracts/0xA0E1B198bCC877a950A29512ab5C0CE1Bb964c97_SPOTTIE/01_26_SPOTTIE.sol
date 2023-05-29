// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Spottie WiFi
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                 //
//                                                                                                                                                 //
//                                                                                                                                                 //
//                                                                                                                                                 //
//                                                                                                                                                 //
//                                                                                                                                                 //
//                .:oxkOOOkxoc,.                                                                          .;ooooo:.                                //
//              ;k00NMMMMKl:OMW0l.                                              cOOOOo'      ;Oc .dx,    .,kMMMMMO.                                //
//             '0MWWWMNK0OdoKMMMWo                                              dMMMMWO'     cWKdkNN:     .:kOOOOo.                                //
//              lWMMM0;...,kWWWWWk.  ....... .';,. .             .;::,.      ..,kMMMMMXc''..'dWMMMMNo...   .,,,,,.        .,::;,'.                 //
//            'lOWMMMNkc;'..,,,,,'. .oNXXXNOdONWNkdOOc.     .cxo'lXMMNOkko'  oNX0KWMMMWXo;xXNWMMMMMMNXNk..'dNNNXNx.   .cl,lNMMMWNKkl.              //
//            .xWWMMMWOoOXKOxo;..   .xMNNWMMMWWWMMMWMWk'   :0WMWKXWWWWMMMMNo.lXKkOWMMMWKdlxKXNMMN0KWNKXx..,xNWMMMO.  :0WWNNNK00NMNKNKc             //
//             .cOXWMM0d0WMMMMWNKo. .xWdc0MWO:',oXMWMMWk. :XMMMMWk:',dXWMXKXd..'kMMMMMK:.....oWMXdkXl... ..',xMMMO. cNMMMWO;. .,kKkXMNc            //
//                .:ldOKXWMMMMMMMM0,.dWX0NM0'    lWMMMMN:.kMMMMMO.    dWMKkKK,  dMMMMWk.     cWMMMMN:    .,lxKMMMO.'OMMMMMx.'ddd0WMMMMk.           //
//           .,;;;;,'. ..;ckNMMMMMK; 'OWMMMk.    :NMMMMN:.OMMWWWx.    lWMMMMN:  dMMMMWx.     cWMMMMN:    .,kMMMMMO.,KMMMMWKxONNNNNNNNN0,           //
//           ,0WWMMWNo.    'dxOWMMX: 'OWMMMK,    oWMMMMX;.xMWx,x0,   .xMMMMM0,  ;cxWMMX;     cWMMMMWl    .,kMMMMMk..OMMMMWx,'''''','''.            //
//            ,kWMMMMW0doox0d;xNMM0'.xMMMMWNOo:ckNMMMMMk. ,KWOoOW0l:ckXkldXNl   ckKWMMWKxd;  cNMMMMMXkdc..,kMMMMMk. :XMMMMKo,'';ol',od,            //
//             ;OWMMWWWWMMMMWWMMXx' .xMMMMNkOWMMMWXXWWO'   'kNMMMMNWMMXc.:x:    ;XMMMMMMMMd. '0MMMMMMMMO..,dKXWMMO.  ,kNMMMKoo0WMXdxOc.            //
//              .,lx0OkKWWNXKOdc'   .xMMMMM0lo0XNXd:o:.      ,ok0KxxNXKxl;.      ,dOKKKKK0l   'lokKKKK0d..':,,x00o.    ,ok0d.'kXKOd:.              //
//                  ...''''..       .xMMMMM0'  .''..            .......             ......        .....                   .. ....                  //
//                                  .xMMXO0O'                                                                                                      //
//                                   cOk: 'c.                                                                                                      //
//                                                                                                                                                 //
//                                                                                                                                                 //
//                                                                                                                                                 //
//                                                                                                                                                 //
//                                                                                                                                                 //
//                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SPOTTIE is ERC721Creator {
    constructor() ERC721Creator("Spottie WiFi", "SPOTTIE") {}
}