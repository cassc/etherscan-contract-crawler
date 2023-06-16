// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Signalnoise
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                              .,;'.     .lxc.               .::,,'.         //
//                                                         ....:0WWKkdc,  .kMN0d;           .ldlc:,.          //
//                                                ..';:lollooodXMMMMMMMNd. lNMMWNd.       .o0Oxdc.            //
//                                       .':coddxO0KNWWNXXKKKNMMMMMMMMMMN: ,KMMMMWd.    ,dXWK0k;              //
//                       ...,,';,.',.'lxOKWMMMMMMMMMMMWNXXNNNWMMMMMMMMMMWo .xWMMMMNl..o0NMMWXo.               //
//                     .:kKXWWNNNXNOdKMMMMMMMMMMMMMMWX0kddldXMMMMMMMMMMMMk. .OWMMMMN0XMMMMMWo                 //
//                 .:oOXWMMMMMMMMMMOdXMMMMMMMMMMMMMXl..   .dWMMMMWXNMMMMMNc  ,KMMMMMMMMMMMWO,                 //
//             .,oONMMMMMMMMMMMMMW0:.:dkOk0NMMMMMMNl      lNMMMMM0cxMMMMMMO.  lNMMMMMMMMXk;.                  //
//           'o0WMMMMMMMMMMMNKOxl;.       lNMMMMMWx.     ;KMMMMWO, '0MMMMMWl  .xMMMMMMMk'                     //
//         .dXMMMMMMMMWN0xl:'.           .OMMMMMMK,    .cOMMMMMXc',cOWMMMMMO.  oWMMMMMK;                      //
//        .xWMMMMMMMNOl;..               oWMMMMMWo   .,xNWMMMMMWNXWWXKNMMMMX; ,0MMMMMNl                       //
//        .OMMMMMMMMWX0000OOxdoc;.      ;KMMMMMMO. ,xKNMMMMMMMMWXKX0d:dWMMMWl.kMMMMMWx.                       //
//         :KMMMMMMMMMMMMMMMMMMMWXk;.  .dXNMMMM0, .kMMMMMMMMMMNKd:,.. .OWWMMdcXMMMMMO'.. ..........           //
//          .ckKNNXNWWWWMMMMMMMMMMMWx. ;xkXMMW0,   cKMMMMMN0d:'.       ;xONWxxWMMMWO,,x0O0XXXXNNXX0kl,.       //
//             ....',;;,;;:clxXWWMMMWl.d0NMMNx'    'OMMMMNd'        ,:. .,dNKONMMMXkOXMMMMMMMMMMMMMMMNO;      //
//                          .lKNWMMMNo:kXMMXo.    .xWMMWNk;.     .;oOOdlc,'xOkNMMKkKMMMMMMMMMMMMMMMMMMMNo.    //
//                      .;oOXMMMMMMXl,l0WMWx.     lNMMXo;,.    .oOXWWWMMWX:'xKWMNc'OMMMMMMMMWXXKNWMMMMMMN:    //
//                  .,cx0XWMMWWMWXd'..c0NNXo:cldxONMMMXxoc.   :0MMMMMMMMMMO.,0WNd.lNMMMMMMO:'....lXMMMMMMx    //
//              .,:lkKNWMMWXKXXkl,..:lkXNWWNWMMMMMMMMMMMMWk. .OMMMMMMMMMMMWc.oOc.,0MMMMMMK;      .xWMMMMMO    //
//          ..,ckNNNWWNXXKkoclokO0KXNWMMMMMMMMMMMMMMMMMMMMMl.dWMMMMMMMMMMMMo    .xWMMMMMWo       .xWMMMMWx    //
//      ...;lkKNNNXKOxc;;'.  ,kXMMMMMMMMMMMMMNKO0O0WMMMMMMNddWMMMMM0OWMMMMMk.   :XMMMMMWO.       cXMMMMMO'    //
//     .,cxKXK0kdol:'.      .:kNMMMMMMMMMNkoc'. .cOWMMMMMWxdXMMMMM0',KMMMMMX:   oWMMMMM0'       :KMMMMMK;     //
//    .':loo:'..             .c0NWMMMMMMWd.   .cONMMMMMKkc;0MMMMMK;  ;KMMMMMk'.,0MMMMMX:      .oNMMMMMK;      //
//                             .lXMMMMMWk. .;dKWMMMMW0o. .dWMMMMNo',:l0WMMMM0;.dWMMMMWd.     cKWMMMMNx'       //
//                             .xMMMMMM0;'lONMMMMWKd;. ..cXMMMMMWXXWMMWWMMMMNc:KWMMMMO'   .:kXWMMMWO;         //
//                             ;XMMMMMMKONMMMMWXx:. .:kKXNMMMMMMMMMMMN0dkWWWWOOWMMMMN:  .:xO0XWMNk;.          //
//                             oWMMMMMMMMMMWKx:.    '0MMMMMMMMMMWXOdc'. .kX0NWNNMWNXx,;lldkkKXkl'             //
//                            ,0MMMMMMMMMMMXl.       cXMMMMMMXOd:.       ;Ok0NNWMWKkl;cccdOdc,                //
//                          :kXWMMMMMMMMMMMMNx'      'OMMMMMO,            ckxKWMNKkc,,coc;.                   //
//                       .ckKNMMMMMM0kNMMMMMMMK;    .xNWMMWO'             .oodWW0xl;'...                      //
//                     .,o0NNWMMMMMX; :0WMMMMMMXo.  ;0NWMWk.               ;ccK0o,.                           //
//                    .;lkKKKXWMMMWo.  .:xKWMMMMWk'.,kWX0o.                .;od:.                             //
//                 ..,:;,'..:xNMWKk,      .c0WMMMM0;;OK:.                   .'...                             //
//                 ..      .;xXWk'          .lKWMMW0OO;                         ..                            //
//                          ,xXO'             .ckNMMNl                                                        //
//                          ,k0;                 'dXWK:                                                       //
//                          ,ol.                  .'cxOo:'                                                    //
//                          .'.                       .cdl.                                                   //
//                           .                           ..                                                   //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SN is ERC1155Creator {
    constructor() ERC1155Creator("Signalnoise", "SN") {}
}