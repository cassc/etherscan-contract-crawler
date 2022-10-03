// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SpiritForSpirits
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                             ..                                                 //
//                                                                          .   ..                                                //
//                               ..                                        .;c;'',.                                               //
//                            .oODC0d'.okDCkd:..d0:.ckDCkx:. c0o;oMANTICl. .:::cc:;'..                                            //
//                           .kMNOONMx;OMN0XWWl'xKc.kMN0KWWd.lKd:d00XMWK0o.  ,'..',:ccc:,'..                                      //
//                           ,KMx..dNx:OWd.'kMk,l0;.kMx..xW0,:0o. ..oWX:.    .,.   .''',:ccc:,'..                                 //
//                           .OMK:....,0Wo  dMOcOMo.kMd  lWK;dMO.   cWK;      ,.    ..   ..';:ccc;,..                             //
//                            ;KMNk;  '0Wk;cKMx;OMo.kMO:c0MO,dMO.   cWK,      .,  .,,,.       ..,cc;'.                            //
//                             .oXMNx.'0ALBIEK;'OMo.kMMMMMX:.dMO.   cWK; .cdd::xkodO0Oo.      .....                               //
//                               'xNMd;OMOlc;. '0Mo.kMXNM0;  dMO.   cWK,  l0l,x0O0d0kkk.  ......                                  //
//                           .ox; .xM0lOWo     '0Mo.kMxoNNc  dMO.   cWK,  :Criminalx'....                                         //
//                           '0MO:c0MOcOWo     '0Mo.kMd.dW0' dMO.   cWK,  :0dGeniusDCKl..                                         //
//                           .oNMMMMX:'OWl     .OMo.kMd '0Wd.dMO.   cNK,  ;d. cO0Odxodc                                           //
//                             ,oO0kc. ':,.... .';..ll. .;c:',:'    ;o;...',...:dl'.,:c,.                                         //
//                            .o0XNNN0: ;0KKKK0x; .xNO''kK0KK0kc.  ;KNl:OSPIRITOc:OFORNXd.                                        //
//                           .xWMX0KWMK,cWMNKXWMN:.xNO',KMWXXWMWd. ;KXl:OSPIRITSkdXMNK0NMWd                                       //
//                           ,KMX: .OMNclWMx..dNMx.cOo.,KMO,.cKMK, 'xO; ..cXMXd:'dMMx. lNMk.                                      //
//                           '0MNl  .:;.lWWo  ,KMk;kMK,,KMk. .kMX; cNMd   ,KMXc  oWMO. .;:'                                       //
//                            oNMNx,    lWWo  cNMx,kMK,,KMk. '0MX; cNMd   ,KM0'  '0MWKl.                                          //
//                            .cKWMNx,  DCintheCity,,KMXkxKWMk. cWMd   ,KMO.   'kNMW0c.                                           //
//                              .oXWMXc lWMMMMWXo..OMK,,KMMMMMNk'  cNMd   :XMO.     ;OWMWk.                                       //
//                                .xNMX;lWMO::,.  .OMK,,KMXKWWx. .'dWMx. .oNMO.      .:KMWd.                                      //
//                           .okl. .kMWooWMo      .OMK,,KMkc0MK,.:lkWMk,,;dNMO.  ;xx,  :NM0'                                      //
//                           '0MXc.;0MWllWWo      .OMK,,KMk.cNMk...oWM0c;;oXM0:. oMMk'.oNMO.                                      //
//                           .xest2018'DCllc      .OMK,,KMk..xWWl  cWMk,;:dNMXo:.:XMWNXWMNl                                       //
//                            .oOKKKOo. ,xx;      .lko..okc. 'dkl. 'xk;   'dko,.. ;k0KK0x:                                        //
//                               ...                                                ....                                          //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract S4S is ERC721Creator {
    constructor() ERC721Creator("SpiritForSpirits", "S4S") {}
}