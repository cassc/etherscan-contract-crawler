// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Verified GlitCh
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                      .....                                             //
//                                    .;loc:,..........                                   //
//                           ...:odddxOKXXKKOkxl'..,;'.                                   //
//                    ...  .'';dKXNNNNNNNNNNXXXKxllk0l..                                  //
//                 ..;xk, ;xddkKNNNNNNNNNNNNNNNNXK00Odc:::...':ll,.                       //
//                .,lkX0:'xXK0XNNNNNNNNNNNNNXOoookK0xc:x0Kkood0XKl.   ...  ....           //
//               'cOXXNXKKXXOkKNNNNNNNNNNNNNXxcccxKXX00XNXXKKXXKkl,.......  ...           //
//             .,.'d0XNNXXNNXXNNNNNNNNNNNNNNNXKKKXXNNNNNNNNXXXKOldOxo:....                //
//            .co,;xKNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXNNNNNNNNNNXXKKX0kc'...                //
//            .'cxkk0XNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXNNX0KNXXX0000KX00ko:'..               //
//              ,dkkOKNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKdkKOOOOkkk0X0O0k:....              //
//              'oO00KNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXKxkOkkO0000KXK00Oc...               //
//              .lO0XNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXK0doOOkO0KXXNNXKKOdc;'.              //
//              .:kKXNNNNNXNNNNNNNNNNNNNNNNNNNNNNNX0OOkl',coxO0XXXNNNXKK0Ol.....          //
//            .lx0XNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXO:.... .,oxx0KKXXXXXXNXKx,.....         //
//        .'..:kOXNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXK0d.    .lOXXXXNNNX0KNNNNNKxo:....        //
//       .,olcdO00KNNNNNNNNNNNKOO0000000000OOd::;;'.  .,..;d0doOKXXXXNNNNNX00kd:...       //
//        .;kKKXXNNNNNNNNNNNXNKo,;d0KKKK0OOOx;.       ..;loO0xkKXNNNNNNNNNXXK00d.         //
//         ,0NXNNNNNNNNNNNNNKx;    ;kOxdxxo:'         'lk0XNNNNNNNNNNNNNNNNXXXX0;         //
//         'ONXNNNNNNNNNNNNXx.      .;xKk;.         'dOxoxKNNNNNNNNNNNNNNNNNNXNO;..       //
//         .oXXXXXXXXXNNNNNXKx;.   .  .;;.       .'oKNNNNNNNNXXKKXNNNNNNNNNXXX0l.         //
//         .,dOOOOOO0XXNXXNXK0Oxl,.......,,',,.,okKXNNNNNNNNNOlcckXNNNNNNNX0Od,.          //
//          .'cxkkkkkOKXNNNNXXK0k:. ....,::okOk0XXNNNNNNNNNNN0xddOXNXKXNXK0xc.            //
//            ..:oxkkOKNNNNNNNXX0dcc:,..',oKXXXXNNNNNNNNNNNNNNNNNNNXXKKKOo:'.             //
//              .,dkkOKNNNNNNNNNNXK0Oko:cx0XNNNNNNNNNNNNNNNNNNNNNNNNNK00d,....            //
//             ..;kkkOKNXNNNNNNNNNNXKXXKKXNNNNNNNNNNNNNNNNNNNNNNNXXXXK00x;...             //
//             ..:kkkk0XXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNX000Okxd;...             //
//             ..,xkkkO0XNNNNNNNXXNNNNNNNNNNXXXXNNNNNNNNNNNNNNNNNX000k:.''..              //
//              ..ckkkkk0KXNNNXK000KXNNNNNNNKxlkNXNNNNNNNNNNNNNNNXXXKOxc'.                //
//               ..lkkkkkO0KXXX0kkkOXNXNNNNNKxoONNNNNNNNNNXKKKXNNNNXKOd,.                 //
//                .,:cxkkkkkOOOOkkkO000XNNNNNNNNNNNNNNNNNNXK0kO000Oxl,                    //
//                  ...;clodxdddooxkkkkOKXNNNNNXN0okNXXXKOOOxdooc;'.                      //
//                        ........;dkkkkkO0KXNNNNO;dXK0d,.....                            //
//                                ..cdkkkkkOO000K0Okxc'                                   //
//                                  ..;ldkkkkkkxdl:'.                                     //
//                                      .''''....                                         //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract VFG is ERC1155Creator {
    constructor() ERC1155Creator("Verified GlitCh", "VFG") {}
}