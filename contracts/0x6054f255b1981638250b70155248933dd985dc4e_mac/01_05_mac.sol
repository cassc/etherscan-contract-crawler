// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MacEthur
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    [email protected]@@@@@@@@@@@[email protected]@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@4:                        //
//    [email protected]@@[email protected]@@@@@@[email protected]@@@@@[email protected]@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@4                       //
//    [email protected]@@[email protected]@@[email protected]@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@4:                     //
//    [email protected]@@@@[email protected]@@@[email protected]@@@@@@@@@@@?44??^    ^@[email protected]@@@@@@@@@@@^                    //
//    [email protected]@@@@[email protected]@@@@[email protected]@@@@@@[email protected]^    [email protected]@@@@@@@@@@?4                   //
//    [email protected]@@@@4:[email protected]@@@@[email protected]@4?.       [email protected]@@@@@@@@@@@4                   //
//    @[email protected]@@@@@@@@[email protected]@@@[email protected]@@?!^        [email protected]@@@@@@@@@@@4~.                //
//    @@@@[email protected]@@@@@@@@@@@@@@@@[email protected]@@@@@4         ^[email protected]@@[email protected]@@@@@@@@@@@4       .^^      //
//    @@@[email protected][email protected]@@@@@@@@@@@@@@@@[email protected]@@@@?4.       [email protected]@@@@[email protected]@@@@@@@@@@@4!. :!~^^.      //
//    @@@@[email protected]@@@@@@@@@@@@@[email protected]@@@@@@4.     [email protected]@@@@@@[email protected]@@@@@@?4?44~          //
//    @[email protected]@[email protected]@@@@@@@@[email protected]@[email protected]@@@@@@4:     :[email protected]@@@@@@@@[email protected]@44^^!4~    //
//    [email protected][email protected]@@@@[email protected]@@@@@@@@[email protected]@@@@@@[email protected]@@@@@@@[email protected]@@@@@@@@@@@    //
//    [email protected][email protected]@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@    //
//    [email protected]@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@    //
//    [email protected]@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected][email protected]@@@@@@@[email protected][email protected]@@@@@@@@@@@@@@@    //
//    @@@[email protected]@@@@@@@@@@[email protected]@@@@@@@@@@@@44?4!  [email protected]@@@[email protected]@@@@[email protected]@@@@@@@@@@@@@@    //
//    @@@[email protected]@@@@@@@@4~  ~!~~~~~!4?44!~!^        [email protected]@@@@@@@@@@@@@@@[email protected]@@@@@@@@[email protected]@@    //
//    [email protected]@[email protected]@@@@@@?44     ~!44????4            [email protected]@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@[email protected]@    //
//    [email protected][email protected]@@@@@@4?~     [email protected]@444!~^            :[email protected]@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@    //
//    [email protected]@@@@@@@?44   :[email protected]@^ .    !444:        [email protected]@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@    //
//    [email protected]@@@@@@@@?4   ^4?~!44...^[email protected]@?44      [email protected][email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@    //
//    [email protected]@@@@@@@@?4    .  [email protected]@@@[email protected]?44~   :[email protected]   ...:[email protected]@@@@@@@[email protected]@[email protected]@???    //
//    [email protected]@@@@@@@?44!:        [email protected]@@@@@[email protected]?4^ :444.           .~~~~~~~~.  ^[email protected]@@[email protected]@@    //
//    [email protected]@@@@@@@@44        [email protected]@@@444.^44?:[email protected]@@~  ...                        [email protected]@@[email protected]@@    //
//    [email protected]@@@@@@@@@?4 [email protected]@@@@?444~.:4~:~^^~.                          [email protected]@@@@@[email protected]@    //
//    [email protected]@@@@@@@?44 [email protected]@@@@@@@@@@@@@@@[email protected]~                          :[email protected]@@@@@@@@?    //
//    [email protected]@@@@@@@@@?44  :~^[email protected]@@@@@@@@@@@@@@@@@@@@44?::.   ~444:          :[email protected]@@@@@@@[email protected]@4?    //
//    [email protected]@@[email protected]@@@@@@@?4     [email protected]@@@@@@@@@@@@@@@@@@@@@?4~  ^44?4.        :[email protected]@@@@@@@??????    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract mac is ERC721Creator {
    constructor() ERC721Creator("MacEthur", "mac") {}
}