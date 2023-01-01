// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AkashaCoin Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                     .;.                                                                                              //
//                     :d.                                                                                              //
//                    .dx.                                                                                              //
//                    '0x.                                                                                              //
//            .dx,    :Kx.                                                                                              //
//            lNXd.   oXd.                                                                                              //
//            oXN0;  .xNo.                                                                                              //
//            lXXXd. .ONo.                                                                                              //
//            cXXX0: ,0No.                                           ...         .;.       'coo,                        //
//            :XXOKx.,0Nd.      ..                                 ,::xO,        :Kc      ;0d:OKc.       .....          //
//            ;KXxOK:;0Nd.    .ld'        .,cc.        .....',cdl:dd' ;Kd.       ;Xx.    'OO,.cKKo:clllllc::,.          //
//            ;KNdoXxc0Nx.   ,xd.        'kKKXO,    ';,'.     ,0NXo.  .x0,       ,KO;.';ckX0ddoxKN0l;,'.                //
//            ,0Nd;OKx0Nk. .c0o.        .xNd:kNk'.;oc.     .;okXKc     lKl. ..,:lxXXkdooONO:..  :KKl.                   //
//            ,0Nd'dXKKNk'.x0c          cXXc ;0XkxK0c.. .,lkXXN0:      '0OoxkxdlccONd. .kXl      :KXd.                  //
//            ,0Nd.;KXXN0ok0;          .kN0,  :0NOllxOOxdO0KNNKo..     .dKo;:,''',dNO' cX0,       :0Xx'                 //
//            ,0Nd..kNXXXXk'           cKNx.  .lXXklllc,,oKNOo:.'',,;;'.:Kd.    ..:0XdcONx'        ;OXO;                //
//            ,0Nl  lXNNWXl.          .kNXd,;:ccdKNk'  ,xXNk'       .;dxo0O'      .oNOdKKo,,;;,..   'kNKc.              //
//            ;KX:  ,0NNNNXk:.        :XNXO0Ol'. ;OXk;c0XXx.          cKOx0:       ,OXKXk.   .,;;;:,.,xXXd.             //
//            ;K0,  ;0NXNXKXXOc.     .xNNk,.;:cc:;:xXXXXXx.       .':dxl.,Od.       cKXXo.        .;::oKNNd.            //
//            :XO' c00KXNKlcONXk:.   ;0NXo     .':coOXXNKl..,;;cloooc,.   ok.       .lKK:             .,;:,             //
//            lNk,oKo'dNNXl..:xKXk:. lXNK;         .,oOXN0dllll:,..       'o,        .',.                               //
//           .dNOO0c  ,0NNk.   ,d0XkoOXNO.            .;od,                ..                                           //
//           .xNXO;   .oNNK:     .ck0KKKl                                                                               //
//           .cxo'     'ONXd.       .''..                                                                               //
//                      cKN0,                                                                                           //
//                      .xNNo.                                                                                          //
//                       .oko.                                                                                          //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ACE is ERC1155Creator {
    constructor() ERC1155Creator("AkashaCoin Editions", "ACE") {}
}