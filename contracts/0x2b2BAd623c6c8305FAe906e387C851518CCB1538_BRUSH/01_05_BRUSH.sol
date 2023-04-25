// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Brushes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//                              ..          ..                              //
//                          ..   .'.      .'.   ..                          //
//                          .,.   .;,    ,;.   .,.                          //
//                          ';.    ;l.  .l;    .;'                          //
//                  ......  .::,. 'o;    ;o' .'::.  ......                  //
//                   ....::.  .:odOk,    'kOdo:.  .::....                   //
//               ....    .lc    ;OX0k:..;k0X0;    cl.    ....               //
//                 .,.    :kl'..;0OdOOooOOdO0;..'lkc    .,.                 //
//                  .;;,:cdKXOkxoxO0K0000K0OkoxkOXKdc:,;;.                  //
//                        .c0OdOKKXXKXWWXKXXKKOdO0l.                        //
//              ...';;,.   'lxOKXKKNNNWWNNNKKXKOxl'   .,;,'...              //
//            ....   .;oooxkxxOKXXNWWMMMMWWNXXKOkxkxooo:.   ....            //
//                    .l0KKOxkKXKXNWMMMMMMWNXKXKkxOKK0l.                    //
//            ......';c:,',cdxk0XXXNWWWWWWNXXX0kxoc;'':c;'......            //
//               ..',.     .dkxOKKXNKXWWXKNXKKOxkd.     .,'..               //
//                   .',,;ckXOxOkk0XKKXXKKX0kkOxOXOl;,,'.                   //
//                 .,;,',;dKOol:ckkxOOxxOOxkkc:loOKd;,'';,.                 //
//                .,.     :d'   ;00x0d,,d0x00;   'd:     .,.                //
//               ...     ,l,   .l0N0c.  .c0N0l.   'l,     ...               //
//                   ...',.  .:c:,lx'    'xl,:c:.  .,'....                  //
//                  .       .c'   .cc    cc.   'c.       .                  //
//                          .,.    ;c.  .c;     ,.                          //
//                          .'.  .''.    .''.  .'.                          //
//                          ..  .'.        .'.  ..                          //
//                               .          .                               //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


contract BRUSH is ERC721Creator {
    constructor() ERC721Creator("Brushes", "BRUSH") {}
}