// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Back To The Future
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    [email protected]8X8X8X8X8X8X8X8X8X8X8X8X8X8X8X8X8X8X8X8X888X888X888X888X    //
//    [email protected]@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]    //
//    [email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@X8:S    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]:@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]:@[email protected]@:@[email protected]@:@[email protected]@:@[email protected]:[email protected]@[email protected]    //
//    [email protected]%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@88S88X88%8X888S88X88%8X888S88X88%8X888S888%[email protected]    //
//    [email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@8:[email protected]@88S88X8888;@[email protected]@    //
//    [email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]:[email protected]@[email protected]    //
//    [email protected]@[email protected]@@[email protected];[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]:[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]:@@@[email protected]:@[email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@88888888888888:[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    8888888888888888X8888:@X888888:[email protected]@%[email protected]:[email protected]@[email protected]@8S8:@@[email protected]@[email protected]@[email protected]    //
//    [email protected]@@[email protected][email protected]@8888888888X88    //
//    88888888888;X8888;[email protected]:[email protected]@[email protected]@[email protected]@[email protected]@88;[email protected]@[email protected]@88888X88X    //
//    888S888888888X8;%[email protected]@[email protected] 888:[email protected];[email protected]@@[email protected];8XX:888SX8    //
//    [email protected]@[email protected];[email protected]@@[email protected]:@[email protected]@[email protected]@[email protected]@S88X888888    //
//    [email protected]@@[email protected]@[email protected]@888S8888t%t:;[email protected]@8888;[email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@88t888%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@;:[email protected]@8X8%8XX;:[email protected]@[email protected]@[email protected]@88.%[email protected]@8888    //
//    [email protected]@:[email protected]@8XX8:[email protected]:8 [email protected]@  St88888 t:[email protected]@888S8;:@@@[email protected]@8888888    //
//    [email protected]@[email protected]@[email protected]@%[email protected] [email protected]@[email protected]@;[email protected]@[email protected]@[email protected]@888S    //
//    [email protected]@[email protected];[email protected]@[email protected]@@8SS88888.88 t 8.88%88S S8 @XX [email protected]@[email protected]@@[email protected]@[email protected]@@[email protected]@    //
//    [email protected]@@8888S;[email protected]: @@88888;[email protected]@@[email protected]@[email protected]@[email protected]@8    //
//    8888X888888888XX8S%%SS8%888888;8;[email protected]@[email protected];@;X8 [email protected]%8.8%t8;[email protected]@[email protected]@[email protected]@@888888;X888    //
//    [email protected]@@;[email protected]%:[email protected]:[email protected]@[email protected] 88%8%888X8888888888;[email protected]    //
//    [email protected]@[email protected]@88X88StS8SXS8S888 [email protected]:[email protected]@[email protected];:[email protected] @[email protected];[email protected]@88X88S888S8X8S888X8888S    //
//    [email protected] [email protected];888S8;8t88888888%[email protected]@t888888888888%8X888%:[email protected]%[email protected]@[email protected]    //
//    [email protected];X8 88888888%88S;;88S8%;@;8%[email protected]@[email protected]@[email protected] 8%8t;t88X88X8%[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]%[email protected]@[email protected]@@[email protected]%8 8 @ @8 8888X 88 @ 8.8 8;[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]%. :[email protected]@[email protected]@[email protected]@X888  @88888X88888 @ @.8;8X%[email protected]@[email protected]    //
//    [email protected]@888X8 [email protected] 88;%@[email protected] [email protected]@[email protected]@@[email protected]@[email protected];[email protected]@[email protected] @ 8 .;;[email protected]@S888X    //
//    [email protected]:%8SX8 S%88%:[email protected]@[email protected]@[email protected]@[email protected]@[email protected] 8:;[email protected]@[email protected];8%[email protected]@[email protected]    //
//    88S88X8S88S8:8888X;;[email protected]%@@8%[email protected]@[email protected]@[email protected]%[email protected]@[email protected]:X8X;%@88 @ 8S888888 X 8:[email protected]@[email protected]@@8X8X    //
//    [email protected]@X8  8%  ; %[email protected]%8;;;@[email protected]@S ;88888t88 .8.8tS8X8;88888% :%%: t  .X;  S:% 8888888 [email protected]  X%@[email protected]:[email protected]@@8X    //
//    [email protected]@888888SX888 ;%8X88%8888888888 [email protected] [email protected]:8:[email protected];;@ 888888 S88888X8888;::;;;:;t%X8XS8888888S8888888X8888SX88:88%@X88888    //
//    [email protected] 888:[email protected]@;8 [email protected] [email protected]@@888XX:8.8%@[email protected]@88888%X [email protected]@88888SX8t 8888S888    //
//    [email protected] @X888:@[email protected]%[email protected] [email protected]@ [email protected]%[email protected] 8 8888888888888888888 88888888888 [email protected]@[email protected]    //
//    [email protected] @ S8%%.%;[email protected] 8.X888X88%8 [email protected]%X% [email protected]%. 88  :%X8X 8S:@[email protected]    //
//    @8X88888 8 [email protected]:88 [email protected]@XS:% [email protected]%[email protected];:8Xt::t:[email protected] ;. ;S888X888%   %8;.;%8888 8::[email protected]%[email protected]    //
//    [email protected]; X [email protected]%8 8888SS888888t8t8;[email protected] 88888 %.%[email protected] 88X:[email protected]@[email protected]@[email protected]:@88;[email protected]%[email protected] 8%;[email protected]    //
//    888888;888888 :X.: %;8X888 888 8%@S8S88  [email protected]@XS88S 8;[email protected]@[email protected]@88888888%;[email protected] 8t.St    //
//    [email protected];[email protected]@X888;X88 [email protected] [email protected] 8SS%[email protected]@88888S [email protected]@[email protected]%%t;XSXS%[email protected] 8;8:@[email protected]    //
//    [email protected]%[email protected]@8   :[email protected] 8888X 888S8%:t :[email protected]@@[email protected]@@@[email protected];[email protected]:%@[email protected]@88. 88;[email protected]:S88X8    //
//    @[email protected] [email protected]@8:t:88888S8%%[email protected]%[email protected]:8;[email protected]%@[email protected]@[email protected]@8X8X8X88XS8S88S8:8;:[email protected]@[email protected]@[email protected]@    //
//    8888X88S88t. [email protected]%[email protected]: 8 8t8SS8S;[email protected]:[email protected]  8% [email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]:88:[email protected]@8    //
//    @[email protected] @888  [email protected]@;8S8S8  t%[email protected]%@;[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@X888888888t888888888:S8:[email protected]    //
//    @[email protected] @[email protected]%[email protected]%%8X8X::. 8 8:[email protected];:888S%[email protected]@8XX8X88888888:[email protected]:@;88X8:St [email protected];[email protected]    //
//    [email protected] 88X%[email protected]@888888:X. :888888%[email protected]@[email protected]:@S8888X8;;8;8;XSt:;;;t%%t8S%[email protected]  [email protected]%8%@@8888    //
//    [email protected]@%;[email protected]:@[email protected]%8.St:[email protected]: %[email protected]@SS%@[email protected]@8;[email protected]@[email protected]@[email protected]%[email protected]@[email protected]%@[email protected]@X88    //
//    [email protected]@SX888X888888. 888X888;8:S  8 8X888S [email protected]@[email protected]@[email protected]@[email protected]@@88%@88888888    //
//    88X8S8X8XX:8888X88 [email protected]@[email protected]%St88:8 [email protected]@[email protected]%8;8 8 8X [email protected] [email protected]@88    //
//    88888888XX;8;SX8XX8S8t X8t8:8X8;8 888;X 8X888t:[email protected]@ tS:;@[email protected]@[email protected]@@[email protected];[email protected]@@    //
//    [email protected]@[email protected] :8 88 SS  [email protected]:8X8X8 [email protected]@@ ;@[email protected]%[email protected]@88%;.88888%[email protected]    //
//    [email protected] 88.88:%@@%8 [email protected]@[email protected];888 ;X8%[email protected]@[email protected]@[email protected]@[email protected]@% %%;%%[email protected]    //
//    [email protected]@X;t8%8%[email protected]@8X:8t888;@;8.X888%88888%@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@888S88888888Xt  ;%[email protected]    //
//    [email protected]@[email protected]@[email protected]@t;%%;.:[email protected]@@[email protected]@[email protected];[email protected]%[email protected]@8888XS88    //
//    [email protected]@[email protected]@[email protected]%%[email protected];[email protected]@[email protected]@[email protected]@88;@;8:[email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]:8888888:8888:[email protected]@88X888    //
//    [email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@888888888888%8888888;@[email protected];@[email protected]    //
//    [email protected]@[email protected]@[email protected]@88S888:[email protected];[email protected]@[email protected]@88888;[email protected]    //
//    [email protected]@8888S8:[email protected]@[email protected]@88888888:[email protected]@[email protected]@[email protected]@@[email protected]    //
//    [email protected]@8888:@[email protected]@@[email protected];[email protected]@;[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]:@8    //
//    [email protected]@@[email protected]@@[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]:[email protected]:X888    //
//    [email protected]@[email protected]@[email protected]@8888X88.%[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@    //
//    [email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]:@S88S88:[email protected]:X888888     //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@@88888%[email protected]@[email protected]    //
//    [email protected]@[email protected]@@8;[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@888    //
//    [email protected]@888S88888X8888%@@[email protected]@[email protected]@[email protected]@X8888888SS8888:[email protected]:%    //
//    [email protected]@[email protected];[email protected]@[email protected]@[email protected]@8S88:@[email protected]@[email protected]@[email protected]:[email protected]@8X    //
//    [email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@8888888;[email protected]:[email protected]@[email protected]    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract dlx is ERC721Creator {
    constructor() ERC721Creator("Back To The Future", "dlx") {}
}