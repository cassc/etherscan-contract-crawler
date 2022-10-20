// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Crypto Hippo
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    8 t;t;t;t;t;t;t;t;t;t;t;t;t;t;t;t;t;t;t;t;t;t;t;t;t;t;t;t;t;t;t;t;t;tt;t;t;t;t;t    //
//    888 @:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:    //
//    888.:@.;;@.X:X:;;@.X:X:;:@:X:;:@:X:;:@:;:@:;:@:;:@:;:@:;:@:;:@:X:;:@.X:X:X:X:X:;    //
//    [email protected] 88.8 @.;;X:@:@.;;X:@:@:;;8:@:;;8:[email protected]:@:@:@:@:@:@:@:@:@:@:@:;;8:@:;;X:;;X:;;@;    //
//    88  [email protected] @;@:;;@[email protected];@:;;@:@:@.X:@:@.X:;;@:S:X:;;@.;;@.X:X:;;[email protected]:@.X:@:@:X;@.X;@.X    //
//    888  8 .;X8 :8.:X8.:8:@.S:X:S8S X:[email protected]:X:X;@[email protected]@ @:8.;8 ;[email protected]:;;@.S:X:S8X S;    //
//    8X .8 8:@ @ @.X S 8.:@8.;@:;[email protected] S8S S X:X8S.;;8.S.   . .88 X 8  ;X88 ;X8.;@ S S:;    //
//    [email protected];@.:;@[email protected] ::@  [email protected] @ S.S ::X:X X X;X.S888S:  ..:@8. 8:@ X @ S 888X S:X;    //
//    88 @ .;8 X:8 X  ;8.:;8   @ X8 [email protected]:       @8888t..    t.8 X.X:X S:X S X88:;@:X    //
//    [email protected]  ;88 ;;8X  :88 @;8 X.8 S 88  . ..       .    .      .::8 :;X:;8X :8X  :8 @.S;    //
//    8 :888.8.8  :[email protected];8X ;@[email protected] ;. ..            .:    .  .. 88 ;[email protected] @[email protected] X:@8 :@:;    //
//    [email protected] 8.:X X:8 @@ [email protected] 88S.  ..  .            .. .   :[email protected] 8.:[email protected] .8X .:@..:[email protected]     //
//    888 88:@.;:8.X8:t::  :@;;:.  .    .           ..   . .8 [email protected] .888 8 @ @:@[email protected];8 [email protected]    //
//    [email protected] @8 ;@88 :X8:.: ...;:  ...   .    .       .  . .  .  S8 8.88X.X.8X X:S:X . 8 :    //
//    [email protected] :;8 X @ 8 . .   ..  . .     .         .     . .   :  88...:8 @  ;X.8.;8:@ @:    //
//    [email protected]:8.:.X.S   . .   .     . .    .  .  .    . .. :. .   ..;8:8.S @:8 @ [email protected];;@    //
//    [email protected] 8:@8S S88:. . .  .   .   .   .       .  . 888:..  . @.;@8.:@.X.. @@ ;X.88     //
//    [email protected] S S 888XS8% .   .   .   .    .  .   . @8 8%SX..  t.  .88.8 ;8 .:88 8  8    //
//    8  @ X   X.:@8 [email protected]@8 . . .  .    .   .   .   .  .:8888:..  X ;:@ [email protected] 8 X;@ @888 @    //
//    [email protected] ..X 8 :8  8S [email protected]; .  .%t.   .       .   .   ..:[email protected] 8:  . t ;8   @8::X:X S @..::    //
//    [email protected] [email protected]   @ .: 8t . [email protected] .;    . .        . ..;t:;. . . 8 X ;;8 @[email protected]:S:;:8:8.    //
//    88 X:;:X:X:@ X:8 XS : [email protected]     .  .     .   .        8 X;8.S8 X8 :X88 ;::8    //
//    8X.:@[email protected]:X:;;@.: S::.S88 [email protected]:.   .   .   .    .  . .  .  [email protected] S @.888 [email protected] @:[email protected]    //
//    8 :8  :@:S:@:@.X;:   .. %%8;..      .   .   .    .       [email protected]; 888 :8 @.X:X.    //
//    [email protected]  :88.X8 :@:[email protected] S.; .....   . .         .   .    . .  . . %8888 @   [email protected] X.t    //
//    8888X [email protected]@.S.X X8         .     .  . .    .   .     .      88888 @:@ X X  .X.8    //
//    888 X :;@ X:S8S S  ;;.: .      .         .    .   .       ..:;.8 @[email protected] :.X @ @ @     //
//    8X @.X;@.;;@ S S:X;@ 88;. .  .   . .  .    .       . .  .   ..  %[email protected]:8 :X X:S X    //
//    [email protected] S:X:X;@:::@:;;@[email protected] St.      .        .    .  .      .          X888 @.:8X :X8    //
//    88.X8X ;;8.X;@[email protected] X..   . . .   .  .     .       .  .   .  .    : %88 :8 @ @  .    //
//    [email protected] .X X;@.;[email protected] S.X S8X.;; .        .   .     . .           .      .. 8 8 ::X.:;8.    //
//    8 8 :;@8 :888;;@ S S @   .  . . .      .  .     .  .  . .    .  .  . @ ;;8.X;@ S    //
//    8 [email protected]:@ @ @ X:8.:8X :8 :            .        .       .      .      . :%888 [email protected] S;    //
//    8888.:X X::;@ [email protected] @ 8 .      .  .    .  . .   .  .     .  .   .    . 8888:[email protected] :;X    //
//    888.8.;8X.8.;8X [email protected] .8            .         .   .   .       .   .  ..8 X.8 .8888    //
//    8X @ [email protected] [email protected]@ @[email protected] @ 8      . . .   . .  .    .       .  .    .   . S8 :@[email protected] X     //
//    [email protected];[email protected] S:S8X S.X X..%            .        .     .  .      .    . .t8 88.X:X ::@    //
//    [email protected]@ S.S.S S:X8S X.%     .  .      .  .    .  .      .     .  . :X 88.;@[email protected]@:    //
//    [email protected] ;@ S:S8X S:S S S8 [email protected] .      .  .     .  .     .  .   .    .  [email protected] :;8 @ .;X8    //
//    8 8 :8X . X.:X8.:X X 8X .   .  .     .    .   .    .      . . .8  @::@;8.. 8.8 S    //
//    8 [email protected]@ @:@[email protected]  .88.;::.       .   . .   .        .     . . .. @  X8.8.;:X88 :;X.:    //
//    8888 .X:X:[email protected] @ X:8.8:@ 8t..         .   . . .    . . . ..S%  8X @ :88   @.8.:@     //
//    888.8.;8X . X .:@.:;@88. 88t . .. .    .     . ..  . t8%8   [email protected] [email protected] X:8 S.X X8    //
//    8X @ [email protected] @:@[email protected];@.X:@ @88    [email protected]    .... ... .    :@[email protected]    ;;88888 X8X S.X.S8S.X ;    //
//    [email protected];[email protected] S:X.S:X.;;@.S.X8 :;:  .:[email protected] :  .;;@:8   88:@88 X.X8S S S:X;    //
//    [email protected]@ [email protected]:X:S.:[email protected]:;t888888888888888  :8.;;[email protected];8 : @ 8 ;X S S.S:;;@    //
//    [email protected] ;@ S:S.S X  .8.S8S @:@.;;8:8 X ..::::::[email protected];88X.:[email protected] :;[email protected] @88X S:[email protected]@:    //
//    8 8.;X8:;@ [email protected] ;;@.X:@.X.;:8:@:X;X;X;8:8.X:;;8 .:[email protected] @:@[email protected] : X @ S:S.S X.;    //
//    8 [email protected] S 8 ;X88 @.S8S X:@:;;@:;;8:@:X:X:X:;;@[email protected];@.X S:X .:[email protected] X S.S8S S:X;    //
//    8888 [email protected] X   8.;X.S S:X:@:@.X;@.X8S ;;X:@;@.;;@ S X.S:X:S:S8X X;@.;:X.S8S S X:S8X    //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract CH is ERC721Creator {
    constructor() ERC721Creator("Crypto Hippo", "CH") {}
}