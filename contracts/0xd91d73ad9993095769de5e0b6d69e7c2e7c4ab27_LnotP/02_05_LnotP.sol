// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lines of the Poetry
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//                                                                                //
//      .  . .  .  . .  .  . .  .  . .  .  . .  .  . .  .  . .  .  . .  .  .      //
//       .       .       .       .       .       .       .       .       .   .    //
//         .  .    .  .    .  .    .  .    . .... .  . .    . .    .  .    .      //
//     .       .       .       .       .  . .;%XXX%:  .   .     .      .          //
//      . . .    .  .    .  .    .  .   [email protected]%X88X: .    .    . .    .  .     //
//            .   .   .   .   .   . . :8X.:t;tttt;;;.:8X:;:    .      .   .       //
//      .  .    .   .   .   .   .   .XX;::;;;;ttttt;tttSX%tt;::  . .    .    .    //
//           .        .       .   :t8t::%[email protected]%S%%t;...;%[email protected]%XX%%:. .    .      //
//      . . .  . . .     . .    ;[email protected] S88.;:     .;@8888SS88%[email protected]   .        //
//        .  . .    ... .    .tXt;:XXX;t:.t::;;;[email protected] .;S;.;St:;[email protected]; .   .     //
//     .   .    . ...  [email protected];::;S8% :@SXS;;t;;;;::;;:t88. .%% .St.:t% .         //
//       .   . . . ....  : [email protected]: [email protected]@8S%[email protected]@8888SSSt:..Xt;%:  S% ;X.;t8   . .     //
//      .  .     .   :..: 8X::[email protected]%t%8;%[email protected]:;tt;;S%8X .S;tX ;X; .         //
//          .  .  ..  .: %88 .;8:X8888;[email protected]@[email protected]%@%:. .:%t;%t8:;8X..8t .   .      //
//      .    .  . .....: XS8;t 88X  t888:@%X8:;XS%XX:;;. %t;;.8t8t :8    .   .    //
//     .. . . . ... ...:[email protected];;[email protected]%[email protected]:%[email protected];;::::X;t %Xt%:.8:.    .      //
//    .... ... . ..;:..: @8:[email protected]@S S;X888S88S [email protected];:tt;:%[email protected] .        //
//    .::;.   ..  :;t::: [email protected];8X @%8%@8StXSt%.. :@[email protected]@[email protected]   .      //
//     . ..:.  .. ::t8 :[email protected]@@[email protected]@[email protected]@t88%:8t;:.  %%8.SS;;;[email protected]@;%@S;8tt    .    //
//        ..%:  .. .%%X88;8;8.8888S;8888%%@%.88tXS tX::[email protected]@;;X:.;XS; .      //
//     .     St .::;[email protected]@[email protected]: 8.8888888;8.8 S888X.8;;  tX :t;@8S XS: X:X  .     //
//      .   . ;8:[email protected]@[email protected]@@X8 %:8888; [email protected];[email protected]@tX; :.X; [email protected];S;. 8.       //
//     . .  .   ;X [email protected]@@.8X8..  @ [email protected]:;8XS .%; t.SS.:%t%[email protected] t;XS;t S8; .     //
//    . .    .88 [email protected]@[email protected]:8St:.. . 8;[email protected]:8t. [email protected];tStt;8.8X;S.;@St%[email protected]; .     //
//     .  . ;[email protected]@@@@8SXS88..:;8;..t88XX :[email protected]:X @ tt [email protected]@8%:%8S%[email protected]  .    //
//         ..%t;S88%[email protected]  % ;t8 ;t  :[email protected]%888. S %;:@[email protected]%: :%@Xt .      //
//     . .SSStt:;888 888S;[email protected]   : X8 ;:8:88 %t 8t; @8;@ 8 S8 8;%8X: .%%%@% .  .    //
//      ..SS%%%@@[email protected]@[email protected]%[email protected] 88888X S  [email protected] [email protected]%XSX888t          //
//     . [email protected]@[email protected]  :%S: [email protected]:;888 [email protected] XS%@[email protected];.   . .      //
//        t%S8S [email protected]@8;8%8S  t%8..8 [email protected] 8X%8888:%t8 8X 8S 8X;t%X%;..  .    .     //
//      . .tX88S:[email protected]@8t88:[email protected]@8; %%[email protected]@888t::  t8 8%[email protected]:. ....    .       //
//       .:8888XX [email protected];;[email protected]; [email protected]@[email protected] X.; 88X%[email protected]    .    .  .   .     //
//      .. [email protected]@8888;8t... %@;8::t%[email protected]:;S8S:@[email protected]@XtX; :.    . .      .    //
//     ...;:[email protected]; . ..88S%88888888888:.;8X888 @8X8SSt.:::.   . . .       //
//    .:.:88 :X%[email protected]%  8.  t%88888 XX88 .XXS8t 8:888SS;;..;;  .  .    ..    //
//          .%S8%[email protected]%St .  ;888888;[email protected] [email protected] [email protected]:.:. .    . .  ..    //
//     .     :t%[email protected]@88:@% 8t  St888%8;[email protected] @@ [email protected]%%%..      .   .  . .    //
//           :88;8 8 88888 888%: [email protected];8%X;[email protected];8SXS%88;;:8      .   .      .    //
//     . :::[email protected]%X8888%.888 8;:.SXtX8SXS8tX888%.8             . .       //
//     . ...  .8888888 8%X @88S88 [email protected]@ %@@@@SS 8XXX8t%8t        . .      .      //
//      . ..  ;[email protected] :8.%:88;:[email protected]:% ;8S%88;:8S8tt:@8:.8%; 888;%8   .  .   .    //
//     .  ..:. .:88888888888888888 8. :8.8888;.:8; %8S:.8 [email protected]@ . 8t%    .   .      //
//      ...  :;;%[email protected]@@[email protected] .t%:::::;:.;8t88Xt.:   .:@[email protected]:  .    .        //
//     .    ;;::;[email protected]    S8  %@ t.%S.::8.   .::X.:%% . . . S8:      .     .      //
//       . %%[email protected]@[email protected]   %   .8.%;:S:.8;.. . ..  t :; .8. . 88     .    .    .     //
//     . . S% %X8S%t::;;tt;:.8:%tt: :..   .....:S%%8 ... .88 .  .   .   . .       //
//        . [email protected] ..   .   . t;8t%: . 8. . . ... 8 : ; 8. %8t       .   .     .     //
//     .   tt;.  . .   .  ; :S% .   .     .:.. X  8: . %8t    .  .  .   . .       //
//      . ..:8   .      .%XS%; .      .  .     ;XtS: .%8;.        .   .     .     //
//          :8      . [email protected]: .    .    .  . . S.:SS.;SSt   . . .    .   .         //
//      . . .  . .   . 8XX .    .   .       . @S.:S:@%%  .       .    .   . .     //
//           . .   . :8Xt.    .   .   .  .   .: X;X%tt.     .  .  . .   .         //
//     . . ..     . [email protected]:X:. .    .   .   .  . @X:@S8SS:::..      .  .  .  . ..     //
//      .     .   . St;[email protected]@S.        .      88.:.   .:;ttt%%%t;;:%:8  :t .       //
//       . .   .    .t;..tX%;  .  .      . . SX%%t;:;::;:;:;;:;;;%%;8888t. .      //
//      .    .   .   .   .       .  .  .       .     .           .     ..   .     //
//        .    .   .      . . .      .    .       .    .  .  . .   .      ..      //
//      .  . .   .    . .       . .    .     .  .   .            .   .  .  .      //
//             .   .       .  .     .    . .      .   . .  . .           .        //
//      . . .    .   .  .       .     .       .     .     .    .  . . .    .      //
//                                                                                //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////


contract LnotP is ERC721Creator {
    constructor() ERC721Creator("Lines of the Poetry", "LnotP") {}
}