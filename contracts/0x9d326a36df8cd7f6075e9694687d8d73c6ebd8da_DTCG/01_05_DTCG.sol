// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DeezeyTech_CryptoGlyphs
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                             //
//                                                                                                                                             //
//    .....................................................................................................................................    //
//    .....................................................................................................................................    //
//    .....................................................................................................................................    //
//    ..................................................................  .................................................................    //
//    ................................................................;oddl,...............................................................    //
//    ............................................................'cxKWMMMMNOo;............................................................    //
//    .........................................................,lkXWMMMMMMMMMMWKxc'........................................................    //
//    ......................................................:d0NMMMMMMMMMMMMMMMMMMNOl,.....................................................    //
//    ..................................................'cxKWMMMMMMMMMMMMMMMMMMMMMMMMN0d:..................................................    //
//    ...............................................;oONWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl,..............................................    //
//    ...........................................'cxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0d:.. ........................................    //
//    ........................................,lOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc'. .....................................    //
//    .................................. ..:d0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNOo;. ..................................    //
//    ............................... .,lkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKx:'. ..............................    //
//    ...........................  .;d0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl,. ...........................    //
//    ........................ .'cxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0d:.. .......................    //
//    .......................;oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxdOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkc,. ....................    //
//    ................. .':xKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;..,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo;.. ................    //
//    .............. .,lkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk,:xkl,dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc.  .............    //
//    .............. ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx,lXMMNo'oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO. .............    //
//    .............. :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo'oNMMMMWx'cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl'dNMMMMMMWk,:KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:'kWMMMMMMMMWO;;0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;,OWMMMMMMMMMMMK:,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,;0WMMMMMMMMMMMMMXc'xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx'cXMMMMMMMMMMMMMMMMNo'oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd'lNMMMMMMMMMMMMMMMMMMNd'lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl'dNMMMMMMMMMMMMMMMMMMMMWk,cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc,xWMMMMMMMMMMMMMMMMMMMMMMWO;;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0:,OWMMMMMMMMMMMMMMMMMMMMMMMMW0;;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;;0WMWkcccccccc::::cccccccl0MMMKc,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk,:KMMMWKkkkkkkkx, .ckkkkkkkOXMMMMXl'dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx,cXMMMMMMMMMMMMMNc..xWMMMMMMMMMMMMMNo'oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo'oNMMMMMMMMMMMMMMNc..xMMMMMMMMMMMMMMMWd'lXMMMMMMMMMMMMMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMMMMMMMMMMMMXl'dNWWWWWWWWWWWWWWWNl..xWWWWWWWWWWWWWWWWWk,:KMMMMMMMMMMMMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMMMMMMMMMMMK:'kKd::::::::::::::cl,..:l::::::::::::::ckNO,;0MMMMMMMMMMMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMMMMMMMMMM0;,OWN0kOkkkkkkkkkkkkxc.  'okkkkkkkkkkkkkkk0WMK;,kWMMMMMMMMMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMMMMMMMMWO,;0MMMMMMMMMMMMMMMMMMMNc .dWMMMMMMMMMMMMMMMMMMMXc'xWMMMMMMMMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMMMMMMMWx':XMMMMMMMMMMMMMMMMMMMMNc..xWMMMMMMMMMMMMMMMMMMMMNo'oNMMMMMMMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMMMMMMNd'lXMMMMMMMMMMMMMMMMMMMMMNl..xWMMMMMMMMMMMMMMMMMMMMMNd'lXMMMMMMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMMMMMXl'dNMMMMMMMMMMMMMMMMMMMMMMNc..xWMMMMMMMMMMMMMMMMMMMMMMWx,cKMMMMMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMMMMKc,xWMMMMMMMMMMMMMMMMMMMMMMMNc..xWMMMMMMMMMMMMMMMMMMMMMMMWO;:0MMMMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMMM0:,kWMMMMMMMMMMMMMMMMMMMMMMMMX: .oWMMMMMMMMMMMMMMMMMMMMMMMMW0:;OWMMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMWO;,kNWWNWWWWNXOxxxxxxxxxxxxxxd:.  .cxxxxxxxxxxxxxxxOXWNWWWWWNN0:,kWMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMKc';cccccccccc:,''''''''''''''........'''''''''''''',ccccccccccc;':OWMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMWXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0' .............    //
//    .............. :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0' .............    //
//    .............. ,ONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNd. .............    //
//    ............... .,lOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc'. ..............    //
//    .................. .'cxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0o;.. .................    //
//    ........................;oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl,. .....................    //
//    ......................... .'cxXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0d:.. ........................    //
//    ............................ ..:d0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXOo;. ............................    //
//    ................................ .,lkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc'. ...............................    //
//    ................................... .'cxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0o;.. ..................................    //
//    .........................................;oOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkc,. ......................................    //
//    .......................................... .'cxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0d:.. .........................................    //
//    ................................................;oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl,...............................................    //
//    ...................................................,lkXWMMMMMMMMMMMMMMMMMMMMMMWKx:'..................................................    //
//    .......................................................:d0WMMMMMMMMMMMMMMMMNOo;......................................................    //
//    ..........................................................;oOXWMMMMMMMMWKkc'. .......................................................    //
//    .............................................................'cxKWMWN0d:.............................................................    //
//    .................................................................;c:,................................................................    //
//    .....................................................................................................................................    //
//    .....................................................................................................................................    //
//    .....................................................................................................................................    //
//                                                                                                                                             //
//                                                                                                                                             //
//                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DTCG is ERC1155Creator {
    constructor() ERC1155Creator("DeezeyTech_CryptoGlyphs", "DTCG") {}
}