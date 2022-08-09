// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ArtAngelsNFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//     .  . .  .  . .  .  . .  .  . .  .  . .  .  . .  .  . .  .  . .  .  . .  .  . .  .  . .  .  . .  .  . .  .  . .  .  .       //
//       .       .       .       .       .       .       .       .       .       .       .       .       .       .       .   .    //
//         .  .    .  .    .  .    .  .    .  .    .  .    .  .    .  .    .  .    .  .    .  .    .  .    .  .    .  .    .      //
//     .       .       .       .       .       .       .       .       .       .       .       .       .       .       .          //
//       .  .    .  .    .  .    .  .    .  .    .  .    .  . . .:;:..   .  .    .  .    .  .    .  .    .  .    .  .    .  .     //
//      .    .  .    .  .    .  .    .  .    .  .    .  .  :8%.X8888;.:X88t  .  .    .  .    .  .    .  .    .  .    .  .         //
//        .       .       .       .       .       .   [email protected]:8    ...    [email protected]@8:8;:.   .       .       .       .       .       . .     //
//      .   . .    .  .    .  .    .  .    .  .    :8;% ..   .:;;:.    ...  :[email protected];    . .    .  .    .  .    .  .    .  .           //
//        .     .    .  .    .  .    .  .    .  . %S ..:;;; @S %[email protected];t8 ..:.   XS%.      .    .  .    .  .    .  .    .  . .  .    //
//      .    .   .       .       .       .      :;  .;t;  @S:      . .t8 8  ...S;;  .  .  .      .       .       .                //
//         .   .   .  .    .  .    . ..;:. .  .X8  .; .S      .  .        t;X.:.. S:     .:;:. .   .  .    .  .    .  .  . .      //
//      .    .      .   .   .   .  ;[email protected]@8XS:  SX...;8%     .  .:. .:. .  .  ;S 8   t.. :[email protected]@8;S    .   .   .   .   .   .    .    //
//        .     . .   .   .   . :8t8tXXt;S8;[email protected]@.;;:t;    .   .: :.S S      . ::;:   ..8;@[email protected] [email protected];%.     .    .   .   .    .      //
//      .   .           .     ;;8%8: 8%. :88;  :t.S.  .  .%S%%X [email protected] .t: .        %   8 [email protected]: .t8  %:8X8..    .    .        .        //
//        .   . .  . .     . X8 8:t 88.;;8S:  :;%:       tS    ...:;: 8.% .  .  .tS .. @88;;;S;[email protected]:  t;.     .     . .  .   .     //
//      .         .    .   :;X;t;tSt.X X8X.;8.;S t . . . ; t8.:; X88S .: 8     . :[email protected]  8t:88X.;St8S8:[email protected]@%: .    .  .       .       //
//         . .  .    .   [email protected]@8%@S; .      Xt .tt:.        . 8 ;;S   .:::.X.  .    [email protected] 8tS.   .   [email protected]%[email protected]:  .       . .     .    //
//      .          .    [email protected]: .   .88. @8 :t:8   .  .   .8 ;t8888.S:; @  .   . X8.t @8: %%% .   ..   8X8X:   .  .     .  .     //
//        .  . . .    .8 %;          :8 8 t8 :t X .     .   8 ;tt;;;;;%;88    .   .::8:@8  % t   .    .   S :: .     .     .      //
//      .           .::8t;8X:  %@. . X%[email protected] S8 ;t.8.   .    . 8 ;t %;.;8.:: ..       S88:t8..%@::   t:@  @8 @Xt8X. . .   . .        //
//        . .  .  ..X8 X;S8: :t8:   :.8t8:8% ;;:.  .   .   .8 ;;t      :;; : .  .  @ [email protected]%[email protected]::  :tS:X @t.X @.8;t          .     //
//      .       . ;[email protected];8:.;%;;8. .:: t%;88X;;tX;   .   .  8 ;tX . [email protected]@;tt8:   .  .88;:%[email protected]%::  ;;  @[email protected];8.: XS%Xt; . .  .       //
//         . . :X:8St8t8 X:;%%::@tSS::  .: ;: ;;;..      ..8S.;t 888S .tt 8 .      @t: : .:.  :%S 8S% %;.:X  ;%[email protected] @X8      .     //
//      .     [email protected] 8:   .XS.  t%.S;  .    [email protected];;.::  .  :.%tS .SS  8;.t8 .   . . SX.X;   .     [email protected]  .         .:;:   . .       //
//        .     .                  .     .  .88;:;.:   .      ;.t X..       .    ;[email protected]; .    .  .    .   . .  .       .      .    //
//      .   .    .  . . .   . .  .   . .    [email protected]:;;..;    .   : : % %    .     .S88:@X .   .       .            .  .    .  .      //
//        .   .           .     .        . 8%; 8S.:;: ;t.   .   .    .     .  %% .%:; ;%8.   .  .     . .  . .       .            //
//      .    .  . .  .  .    .    . .  .  :t.  ;@;  :..SX.             .    .%8:tX8.   .t:     .  .  .         . . .   .  . .     //
//         .          .    .   .         :;%: [email protected]:X8S .::.X;XX:.  . . . .%[email protected]@t SS  @8 :%:: .       .   . .  .       .            //
//      .     .  . .     .   .   .  . . :.t; [email protected] :;:%t8 ..::: S88%[email protected]   X8%t8: :: [email protected] ;%..  . .  .           .  .     . .  .    //
//        . .        .  .      .        @XX .t:  8t. ..S X.:;::::;;;;:: [email protected];@:   .;8  .;. [email protected]      .   .  . . .      .  .          //
//      .     . .  .      . .    . .  .t8X  S8S t8S .8% .:@%;[email protected]@88X:;8%.  %8. S8t S8S  X8t.  .      .        .  .      . .     //
//         .         . .      .        ..  [email protected]   8: SSX [email protected] ..      . .  [email protected] @%S :8.  88% ...      . .    .  .   .    . .         //
//      .    .  . .      .  .   .  . .  .   . .88S  [email protected]:@X  88  [email protected]: 8XS .8   X88. .      .  .      .      .    .      .      //
//       .          .  .      .           .    t%  :8%  @t; tX8 ..   @X; ;;@  %8: .%;   . . .   .   .  .   . .    .    .     .    //
//         . . .  .      . .     .  . .  .  . [email protected] .88%   @. %%X  tt .X%% [email protected] %88  [email protected]       .   .      .      .    .   . .      //
//     .  .         . .      .  .            :X.. .;   :X%  8X%   .  %X8  tX.   ;.   X:  .  .        .     .  .    .   .          //
//           .  . .     .  .      .  . .  .  %;%  SS8  %@8  [email protected];  ..  ;@X  [email protected]% .8XS  %;t        .  .   . .       .    .    .  .    //
//      .  .         .        .    .     .    .   t8:  88t  %t. .tt. .tS  t88  :8t . .  . .  .     .      . .     .     .         //
//       .   . .  .    . .  .   .     .    .    . 88 . .t   .;.      .t.  .t.  .88.         .   .    .  .     . .   .  .   .      //
//     .           .       .   .  .     .    .   ..    .  . S    ;t    S    .   .   . .  .    .   .       .       .      .   .    //
//        . .  . .   .  .    .      . .   .    .    .    . .8t  ..: . [email protected]:  .     .      .  .    .   . . .   . .     . .    .      //
//      .             .   .     .  .        .     .   .    :;8   ;t   8;:    . .   .  .      .    .             . .     .         //
//        .  . .  . .       .    .    . .  .  .     .   .  .  .  :; . .   .              .     .     .  . .  .       .    .  .    //
//      .              . .    .     .           .        .     . XX     .   .  . .  .  .   . .   .          .  .  .    .    .     //
//         . .  . .  .     .   .  .    . .  .  .  .  . .    .      .  .      .     .     .         . . .  .         .    .        //
//      .      .       .     .      .      .       .      .   .  .       . .    .    . .    .  .  .      .   .  . .   .    .      //
//        .  .    . .    . .   . .    .  .   .  .    .  .   .      . .  .     .   .       .     .    .     .        .   .    .    //
//      .       .     .      .     .           .  .       .    .           .    .   .  .    . .    .   .     . .  .       .       //
//        . . .    .    .  .    .    . .  . .       . .      .   . .  .  .   .        .  .       .   .   .       .   . .    .     //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AAN is ERC721Creator {
    constructor() ERC721Creator("ArtAngelsNFT", "AAN") {}
}