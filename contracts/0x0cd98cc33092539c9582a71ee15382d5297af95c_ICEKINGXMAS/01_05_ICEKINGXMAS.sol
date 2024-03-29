// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Very Ice King Christmas
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,***************.**.* *.* ,***,*,** **.,****** *** ,* * * * ****,***************    //
//    ,*******,******* ****,* ,,,,****,*,*.*.* *******,*,,**,,,*,.****,*******,*******    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ............................................................ .. ................    //
//    .......................................................  ....... . ., ..........    //
//    ...................................................... . ....... ..,... ........    //
//    ........................................................... ....................    //
//    ...................................................... ..... ....... ..  .......    //
//    ............................................................ .......   .........    //
//    [email protected]  @@[email protected]######@,............... .. .. ....... ..   ......    //
//    ........................   ......#######@............ .......  ...... ..........    //
//    ................................#########@.... ...... ...,.... ..  ..  .. ......    //
//    [email protected]###########&... ............. .... ...    . .....    //
//    ..............................############@@@...................................    //
//    ..............................                ..................................    //
//    ..............................          @,,,    ,...............................    //
//    .............................  *@..******&@**,  .  &............................    //
//    ............................. @*,.******,**#***        .........................    //
//    [email protected]   ,*#,* , **            &&&&  &.....................    //
//    ........................           @  ,* &@&          &&@&&&....................    //
//    [email protected]            @& ,%/*.            &&&&&&&..................    //
//    .....................      @**,       **              /&& &&&&&@................    //
//    ....................      &&@*        ,               &&&  @&&&&&...............    //
//    ....................     &&&&&       ,                &&@   @&&&&&..............    //
//    ....................    &&&&@       &                &&&%   @&&&&&&.............    //
//    [email protected]@  &&&&#                        @&&&   @&&&&&&&.............    //
//    [email protected]&@&&&&                         ,&&&&  @&&&&&&&&@............    //
//    ....................&&&&@                         &&&&&   &&&&&&&&&&............    //
//    [email protected]&&&                        &&&&&  (@@&&&&&&&&&............    //
//    ......................&&&&@@@                  &&&&&&  &&&&&&&&&&&&&............    //
//    ......................&&&&&&&&&&@           @@**(&@&  &&&&&&&&&&&&&&............    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract ICEKINGXMAS is ERC1155Creator {
    constructor() ERC1155Creator("A Very Ice King Christmas", "ICEKINGXMAS") {}
}