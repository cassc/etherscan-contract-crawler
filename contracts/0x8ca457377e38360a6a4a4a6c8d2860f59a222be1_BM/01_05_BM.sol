// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bean Monger
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    [email protected]@[email protected]@8888888888888888888888888888888[email protected][email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@8888888888888888888888888888888[email protected][email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@    //
//    [email protected]@8888S88888888888888888888888888888[email protected][email protected]    //
//    [email protected]@[email protected];.::;tS888888888888888888888888888888888888St;...;[email protected]@[email protected]@88%[email protected]    //
//    [email protected]%[email protected]@;.  .    . [email protected]   . .   .;[email protected]@8    //
//    88888888888888888888888888888S   ..:::;;%@[email protected];:::::   .%[email protected]@    //
//    [email protected]%[email protected]:%[email protected]@8    //
//    888888888888888888888888888;  .88888888888888888888888888888888888888888888888888888888888;%;[email protected]    //
//    88888888888888888888888888tXt%S8888888888888888888888888888888888888888888888888888888888t t%X88888888888888888888888888    //
//    [email protected]@88888888888888888888S% 888888888888888888888888888888888888888888888888888888888888%tS:@[email protected]@88    //
//    88888888888888888888888888S88%@888888888888888888888888888 8 8 [email protected]@8888    //
//    [email protected];[email protected]@888888888888888888888 888S8 888 SS 88888888888888888888888888X8tX88888888888;%88888888888    //
//    [email protected]%88888888888888t8888888888888888 888 8888.  % 8S8 8 @X88 [email protected];[email protected]    //
//    88888888888:[email protected]; ;[email protected]@X 8888888888 88888888888S [email protected]@   8 X 8888 88888888888888 @88XS88888888; ;8S;[email protected]    //
//    88888888888X  X  .;[email protected] @8888.88 8888888888888   8   8 [email protected]  8 @ 888888 888888888888X8888888888%  :X;;[email protected]    //
//    888888888888S% %  .:X8888 [email protected] 888 88%  8  888888 @XX 8 88 S 888888 8888 8SX88X8 88888:  ;8St [email protected]    //
//    888888888888X ..    .;@888;@[email protected]  8888888888 8X   % :@8888888888888SX8888 @[email protected]:   [email protected]%[email protected]    //
//    [email protected]%t t   .;[email protected];:88 8888 8888 888S8 88 888 8888 8  8 X%t88888 88888 888%XS:8t88;  . [email protected]; :88S88888888888    //
//    8888888888888t.%S%;S   .:X888888X;;8888 8888%88888 8 88888888 88S8  [email protected] 88 888888 88 8 [email protected]: .  S8: t%88%@8888888888    //
//    8888888888888Xt:SS8:8    .;X888XS:: 88888888888888888%888 88888 88 S8.88888888888888S8  [email protected] ;.  . :88%:[email protected]    //
//    [email protected];8t8;8      %.S8X% t%888888888 88 [email protected]@t88888 [email protected]@ 8 8S8;[email protected]  t%%8t      :88%tXX888S%88888888888    //
//    888888888888888:8;8%8t8    . [email protected]%t.:8 888 88888888 %8;X88888888 88t:@ 888 888888 @[email protected] 8.X.t .   [email protected]%S8S8888X8X8888888888    //
//    [email protected];8X8S88     :[email protected] 88 888 8888888 8:;[email protected] [email protected] t88 8888 8 88 X:8 8 ;. . :@[email protected];%88888888888    //
//    8888888888t8;..:;S88S88888;   . tX 8t%t8 ;88888 8 88888 [email protected] 88 88S 8888888888 888%:8 8;::   %[email protected]@;. :[email protected]    //
//    [email protected]:   ;@88888888.  . %8%88888.X 8888888 88 ; ;888X @@8t88 88 888 S8XS 8:88t . .:[email protected]@88888S;: .S8 ;[email protected]    //
//    [email protected]@@: .;:%@[email protected]@[email protected]; ..;;888888X88  8888888. :.:S8X8X888888 [email protected]%8888 S. .;[email protected] .:@8t%88S8888888888    //
//    888888888888888%%%X :   %[email protected] .:X88888SSX%8888888888% ..888 8 8 8888888%88S8888X.  .X8XXSSXt  .  [email protected]@@8888S888888888    //
//    88888888888888X8%888S. . :[email protected]%tXX8888 t .%888888 8; .. @ 888888888St.X888 [email protected]%[email protected]: . [email protected]@888XS8888888888    //
//    888888888888888%@%[email protected]%:  . :%[email protected]:;[email protected] .:%S%X8X:.  :[email protected] 8%[email protected]:;%88888%:.   :[email protected]    //
//    88888888888.8888S%S88XXXt   .  ;[email protected]   .....  . SX..X8888: .  [email protected]@[email protected]   . [email protected]@888888S8X8888888888    //
//    888888888 [email protected];@[email protected]%;: .  .:%t%[email protected]@[email protected];; .     . 88.:SS8X;. ;@S 8%SXX8X8%%t;:... ..;%%[email protected]@8S888888888888    //
//    [email protected]%tttt;::  :.tt%%. X S   ;     .. .SX8X;;SX%.. ;8;  S XS S%tt.  .:tt%t%t%[email protected]%88X88888888888    //
//    8888888888888 888888%8X888t:;:;;ttt:.;ttt8.X S %;    .  8X 88. 8%:t:  .::.S @ 8;tt;.:[email protected]@%[email protected]@8888888888888    //
//    88888;[email protected];.     ;t.::::::;SXXXS;;tt8 .S8;.  :8SX 88tS8  @ 8X.   %t.%8t;;[email protected]%;;::::.::.. ..%8888888S8888888    //
//    88888888888888888XS%; .. :.  . .:.:ttt%St;:8%8888; 8; [email protected] 888.8 8  88;:t%X% 8S;[email protected]@@XS%;:.    . .:;[email protected]    //
//    888888888SS8888888X%%@@St:.   .  . ...::;;;8 [email protected] 8 8;8:8 8;8 ;@@S8SX8t;;;;..    ..  . :;%%[email protected]@88SX 888888888    //
//    [email protected] 8 88888:88SXXXStt;;:.....:..::t;;S8t8888%;tX888S8:8 8:88tX8:[email protected];;:.......:::;;tt%%%[email protected]@888   8%8888888    //
//    888%[email protected]%%XX%t;;;:;tt%SSSXXt;%S%[email protected];.;[email protected]@8 %%X88S8 :%@X%ttt;[email protected]%%tttttt%[email protected]@[email protected]    //
//    88888 X88 888888 [email protected]@S;;t;;;.. .:tt:::;::[email protected]@8%88%[email protected]@ ;. t;;tt. ..;[email protected]@8X88888888S888 X88 88888    //
//    88888S88 8888 8888888:[email protected]:.. .  ...:;t%tt:;.:t88888888X8%[email protected] ;: ;t;t;:...     ..:tS888888888888X8888888 X8S 8888    //
//    8888 @8 88888888888 88888:8%...  ......:.::;;;;. . [email protected]@88X%X8;%%S8;.  .;;;;::.:.......   ;[email protected]@8X8X8888t888888 8X 8888    //
//    8888 @ 888888888888888888888;.. ..........::. . ..   [email protected];t8:S8S .;..    .:::.:.::.:.:::.:S8S88%888%[email protected] 8888    //
//    8888 X 8888 888888 88888 8888888Xt;:;;t%@:   .....    ; 8888tS88 @;...    . . ;tt;;;;;;tS888X88;888:8888:888 8888 @ 8888    //
//    8888 X 888888888 888888888%8 8:8t8;SSS%St   .. . .   .:  ; 88:;:.::. ...   . . :[email protected];8888888888888888888 @ 8888    //
//    888888 888888 8 [email protected] 888:888 ..   [email protected] ;  .:.  . .t..88;88    .. t%8t88t88;88:8888888X88 8 8888888X 88888    //
//    88888 S 88888888888  @8  8X88 888 888 8X::;[email protected]%%%8t:  .;;.  tt88.88 8;8X; ..;8:8.88.8888888  [email protected] [email protected] SX88888    //
//    888888  [email protected]  [email protected]    88%88 88888 8;8:S%8;8:88 88. ..8% :S8.88 88 88:8;SS%88888888%X  8;@8t%; 8X 88888888X 888888    //
//    8888888  8888888888  @88 8;8  888888S88888 88.8 88%8 8 8S @ 88:;8.8 88S88 88 888.8 8 8%88X 8t8 [email protected]%[email protected]  8888888    //
//    88888888 888X8888888S% %X8 t8  S8 8888888 88 8 8 88 888 8.XS88:88888888%8% 888S888888888XS8.X88XSS8S88888888888%88888888    //
//    [email protected]@[email protected] 8t;[email protected] t8 888888888888888:88X 8S8888:8S:t8 8S8 88:.8888  8 88 8 8S88 [email protected] S88%. 88888888888888888888    //
//    88888 8 .X8 88888888S.8t8.XS888;.888888 S 8 8X @[email protected] 8 [email protected] 888 88 @8X8 @S8 X 8888888%%8:@ [email protected];;8888888    //
//    8888888;.S88888S:;t8%S8.t88  888S 8 888S88 8SSX%S%t .X88888:.;8 8888%XSS8%t.X StX8S8888X8  8:8%8t @%[email protected] ;88t8888    //
//    8888 [email protected]@88X8t.:;8 :@[email protected] [email protected]:@  88SS88:88S; 8888: 888  .X%S8;88:88t  [email protected]  8: 8;88:X:[email protected]@%%@888%X888888    //
//    8888888S8888:. ..tS ::t 8;S;%88S8X88888.;%XXS88 888 [email protected] 8888%.888888X 8:8 88 88;: X88 8X%[email protected]%[email protected] .. [email protected]    //
//    [email protected]@88t .. 8 S888. 8;8t8t..S8888:  XX8;8 [email protected]%% 8 8888t8888:%@S8888 888 8.:;[email protected]%8888888: .. 88S8XX8X88888    //
//    [email protected];t.;:8;;%[email protected]@[email protected] 888.:88S88888XtXX8%88 [email protected]@S [email protected]:%@ . X [email protected]    //
//    [email protected]   8%S. 8%8% %:% 888 8SS @[email protected]@8 8%8 88888888 8 88:XSX8 888 [email protected] 8 8 S888.tXX88X%S8 ;; 8S8 8888;S8888    //
//    [email protected]%8X888888.. @S: 888%:..;8 888  .%[email protected] 88888888888 8%:[email protected]@[email protected] .X8 8.Xt%t%[email protected]:88888    //
//    888888;%8X8 8888888S @[email protected]:@[email protected]%X888;@ %%.8 88 8.8888 88888 88%8888 88.88 88%[email protected]@@S8XX%[email protected];S.%8;@8888888 [email protected]    //
//    8888888:t88888888 [email protected]%X;S%8%8888S.X8S88%;88 88888 888888%[email protected] %:@[email protected]%[email protected]@S88% t%:[email protected]    //
//    88888888SX8S888888888888%888t8888888888; 8%@S888 888888888888 8888888888%888. 8.8888888%888::@8X8888;8; [email protected]    //
//    [email protected] [email protected]@@888X888S88888.88.88:88888 888 8888888888888888888888 88:;[email protected]%8t888888888:[email protected]%t 8888888888888    //
//    88888888888  [email protected]@88 888888;88888888    :888t8 88888 88 8888888 88 88S8S888::   [email protected] [email protected] XX:88888888888    //
//    [email protected]@888888888888888 S88 8;  8.Sttt8888 88888888S888888888.:S:8: :. 8 S8X:88 888888888:[email protected]%8888888888888888    //
//    [email protected]:SS t%St.:t  ; ;@X 888888 8888 88 888 .:%;8; :SSt8t 8.8 8888888888888888888888888888888    //
//    [email protected] 88 %@[email protected]%[email protected]; 8888 88888888888Xt88X8%@[email protected]%%[email protected]%S .S888888888888888888888888888888    //
//    [email protected]@%X%;@[email protected]  tX888888888888 8%:% [email protected]@t;8SSS  [email protected]@8888888    //
//    8888888X%8888888888888888888XtX X8XX88X888888%8888.Xt8888888888 [email protected]%[email protected] @8:X. [email protected]    //
//    8888888888888888888888888 888 8t88X888888t888888888 X 8 8888888888 [email protected]%88888X888 [email protected]@888888888888888888888888888    //
//    888888888888888888888888888 8 888X.8888t888888:88;8 8S888888888888S8t8888888888%88888 XS8%8 8888888888888888888888888888    //
//    8888888888888888888888888888tS8%[email protected]%888888888888888S:88S8888888888888S8X8 888X88888888888888888888888888    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BM is ERC1155Creator {
    constructor() ERC1155Creator("Bean Monger", "BM") {}
}